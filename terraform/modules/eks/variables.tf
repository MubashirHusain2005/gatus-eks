variable "cluster_name" {
    type = string
    default = "eks-cluster"
}

variable "clus_vers" {
    type = string
    description = "Version of Cluster"
}

variable "vpc_id" {
    type = string
}


variable "iam_cluster_role_arn" {
    type = string
}



variable "nodegroup_role_arn" {
    type = string
}

variable "priv_sub_2c" {
    type = string
    default = "10.0.3.0/24"
}

variable "priv_sub_2d" {
    type = string
    default = "10.0.4.0/24"
}


variable "priv_subnet2a_id" {
    type = string
}

variable "priv_subnet2b_id" {
    type = string
}

