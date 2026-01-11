terraform {
  required_providers {

    aws = {
      source = "hashicorp/aws"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.23.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12.0"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
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

##ECR  lifecycle policy to clean up old images to save on storage costs

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





