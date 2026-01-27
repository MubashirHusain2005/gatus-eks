variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "clus_vers" {
  default = "1.30"
  type    = string
}

variable "cluster_name" {
  type    = string
  default = "eks-cluster"
}