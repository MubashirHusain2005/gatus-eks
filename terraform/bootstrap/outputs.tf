output "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.terraform_state.arn
}


output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.terraform_locks.arn
}

output "s3_bucket_region" {
  description = "Region of the S3 bucket"
  value       = "eu-west-2"
}


output "ecr_repository_url" {
  value = aws_ecr_repository.ecr_repo.repository_url
}

output "ecr_repo_name" {
  value = aws_ecr_repository.ecr_repo.name
}