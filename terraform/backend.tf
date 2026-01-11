terraform {
  backend "s3" {
    bucket         = "mhusains3"
    key            = "eks/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}


