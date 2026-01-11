variable "image_tag_mutability" {
  type = string
  default = "IMMUTABLE"
}

variable "region" {
  type = string
  default = "eu-west-2"
}

variable "name" {
  type = string
  default = "ecr_repo"
}

variable "scan_on_push" {
  type = bool
  default = true
}

variable "oidc_name" {
    type = string
    default = "github.to.aws.oidc"
}