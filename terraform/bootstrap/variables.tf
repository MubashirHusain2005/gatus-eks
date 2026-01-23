variable "image_tag_mutability" {
  type    = string
  default = "IMMUTABLE"
}

variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "cart" {
  type    = string
  default = "cart"
}

variable "dispatch" {
  type    = string
  default = "dispatch"
}


variable "catalogue" {
  type    = string
  default = "catalogue"
}


variable "fluentd" {
  type    = string
  default = "fluentd"
}

variable "loadgen" {
  type    = string
  default = "loadgen"
}

variable "mongo" {
  type    = string
  default = "mongo"
}


variable "mysql" {
  type    = string
  default = "mysql"
}

variable "payment" {
  type    = string
  default = "payment"
}

variable "ratings" {
  type    = string
  default = "ratings"
}

variable "shipping" {
  type    = string
  default = "shipping"
}


variable "user" {
  type    = string
  default = "user"
}

variable "web" {
  type    = string
  default = "web"
}

variable "scan_on_push" {
  type    = bool
  default = true
}

variable "oidc_name" {
  type    = string
  default = "github.to.aws.oidc"
}