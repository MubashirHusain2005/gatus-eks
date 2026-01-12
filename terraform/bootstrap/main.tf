provider "aws" {
  region = "eu-west-2"
}

##S3 Bucket to store state file

resource "aws_s3_bucket" "terraform_state" {
  bucket = "mhusains3"


  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name        = "My bucket"
    Description = "Storage for Terraform State"
  }
}

##Enabled Versioning

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

## Enable encryption 

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

##Block All public access- state files should never be public

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

##Bucket policy enforces SSL/TLS connectiosn only 
resource "aws_s3_bucket_policy" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceTLS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

##DynamoDB for Statelock

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"


  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "terraform-lock"
    description = "Terraform State lock for EKS"
  }
}


#OIDC for github actions

data "tls_certificate" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
}


resource "aws_iam_openid_connect_provider" "oidc" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github_actions.certificates[0].sha1_fingerprint]
}


resource "aws_iam_role" "github_oidc_role" {
  name = var.oidc_name
  lifecycle {
    prevent_destroy = true
  }
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" = "${aws_iam_openid_connect_provider.oidc.arn}"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com"
          },
          "StringLike" : {
            "token.actions.githubusercontent.com:sub" : "repo:MubashirHusain2005/gatus-eks:*"
          }
        }
      },
    ]
  })
}

resource "aws_iam_policy" "oidc_access_s3" {
  name        = "s3_access"
  path        = "/"
  description = "Policy to access S3 during CI/CD"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Sid" : "ListStateBucket",
        "Effect" : "Allow",
        "Action" : "s3:ListBucket",
        "Resource" : "arn:aws:s3:::mhusains3"
      },
      {
        "Sid" : "ReadWriteStateObject",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        "Resource" : "arn:aws:s3:::mhusains3/*"
      },
      {
        "Sid": "DynamoDBIndexAndStreamAccess",
            "Effect": "Allow",
            "Action": [
                "dynamodb:GetShardIterator",
                "dynamodb:Scan",
                "dynamodb:Query",
                "dynamodb:DescribeStream",
                "dynamodb:GetRecords",
                "dynamodb:ListStreams"
            ],
            "Resource": [
                "arn:aws:dynamodb:eu-west-2:038774803581:table/terraform-lock"
            ]
        },
        {
            "Sid": "DynamoDBTableAccess",
            "Effect": "Allow",
            "Action": [
                "dynamodb:BatchGetItem",
                "dynamodb:BatchWriteItem",
                "dynamodb:ConditionCheckItem",
                "dynamodb:PutItem",
                "dynamodb:DescribeTable",
                "dynamodb:DeleteItem",
                "dynamodb:GetItem",
                "dynamodb:Scan",
                "dynamodb:Query",
                "dynamodb:UpdateItem"
            ],
            "Resource": "arn:aws:dynamodb:eu-west-2:038774803581:table/terraform-lock"
        },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "oidc_s3_access" {
  role       = aws_iam_role.github_oidc_role.name
  policy_arn = aws_iam_policy.oidc_access_s3.arn
}


#IAM Role for ECR

resource "aws_iam_role" "ecr_role" {
  name = "ecr"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}


resource "aws_iam_policy" "ecr_policy" {
  name = "ecr-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:CompleteLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:InitiateLayerUpload",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:BatchGetImage",
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_policy" {
  policy_arn = aws_iam_policy.ecr_policy.arn
  role       = aws_iam_role.ecr_role.id
}


#ECR to store my Docker image
resource "aws_ecr_repository" "ecr_repo" {
  name                 = var.name
  image_tag_mutability = var.image_tag_mutability

  # Scan images for vulnerabilities on push
  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  # Encryption at rest
  encryption_configuration {
    encryption_type = "AES256"
  }

}

##ECR lifecycle policy to clean up old images to save on storage costs

resource "aws_ecr_lifecycle_policy" "ecr_policy" {
  repository = aws_ecr_repository.ecr_repo.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only 10 most recent images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}


