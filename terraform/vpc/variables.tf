variable "vpc_cidr" {
  default = "10.0.0.0/16"
  type    = string
}

variable "enable_host" {
  default = true
  type    = bool
}

variable "enable_support" {
  default = true
  type    = bool
}


variable "cluster_name" {
  type    = string
  default = "eks-cluster"
}

variable "nodes_name" {
  type    = string
  default = "eks-nodes"
}

variable "cert_issuer" {
  description = "Which lets encrypt clusterissuer to use"
  type = string
  default = "letsencrypt-prod"

}