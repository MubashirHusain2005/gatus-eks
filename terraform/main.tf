data "aws_eks_cluster_auth" "cluster_auth" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca)
  token                  = data.aws_eks_cluster_auth.cluster_auth.token
}

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca)
  token                  = data.aws_eks_cluster_auth.cluster_auth.token
  load_config_file       = false
}

provider "helm" {}


module "vpc" {
  source             = "./modules/vpc"
  vpc_flow_logs_role = module.iam.vpc_flow_logs_role

  depends_on = [module.iam]
}

module "iam" {
  source = "./modules/iam"
}


module "eks" {
  source               = "./modules/eks"
  clus_vers            = var.clus_vers
  vpc_id               = module.vpc.vpc_id
  iam_cluster_role_arn = module.iam.iam_cluster_role_arn
  nodegroup_role_arn   = module.iam.nodegroup_role_arn
  priv_subnet2a_id     = module.vpc.priv_subnet2a_id
  priv_subnet2b_id     = module.vpc.priv_subnet2b_id
  kms_key_arn          = aws_kms_key.kms_key.arn


  depends_on = [
    module.iam,
    module.vpc
  ]

}

module "cert-manager" {
  source           = "./modules/cert-manager"
  cluster_endpoint = module.eks.cluster_endpoint

  depends_on = [
    module.eks,
    module.nginx-ingress
  ]

}

module "external-dns" {
  source            = "./modules/external-dns"
  oidc_issuer_url   = module.eks.oidc_issuer_url
  oidc_provider_arn = module.eks.oidc_provider_arn

  depends_on = [
    module.eks,
    module.nginx-ingress

  ]

}


module "manifests" {
  source                   = "./modules/manifests"
  cluster_endpoint         = module.eks.cluster_endpoint
  letsencrypt_staging_name = module.cert-manager.letsencrypt_staging_name


  depends_on = [

    module.cert-manager,
    module.nginx-ingress,
    module.external-dns
  ]
}


module "nginx-ingress" {
  source           = "./modules/nginx-ingress"
  cluster_endpoint = module.eks.cluster_endpoint

  depends_on = [
    module.eks
  ]
}

module "security-group" {
  source = "./modules/security-group"
  vpc_id = module.vpc.vpc_id
}






