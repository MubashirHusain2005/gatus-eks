provider "kubernetes" {
  host                   = aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes = {
    host                   = aws_eks_cluster.eks_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

provider "kubectl" {
  host                   = aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}



data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.eks_cluster.name
}


##2  Cert manager

#resource "helm_release" "cert_manager" {
  #name       = "cert-manager"
  #repository = "https://charts.jetstack.io"
  #chart      = "cert-manager"
  #namespace  = "cert-manager"
  #version    = "1.16.1"

 # create_namespace = true
  #wait             = true
  #timeout          = 600

  #set = [
   # {
   # name  = "installCRDs"
   # value = "true"
 # },

  #]

 # depends_on = [aws_eks_node_group.private-nodes]
#}





#3  Cluster_issuer yaml file
resource "kubectl_manifest" "letsencrypt_staging" {
  yaml_body = <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: stokemubashir@gmail.com
    privateKeySecretRef:
      name: letsencrypt-nginx-cert-staging
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

  depends_on = [
    helm_release.cert_manager
  ]
}

resource "kubectl_manifest" "letsencrypt_prod" {
  yaml_body = <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server:  https://acme-v02.api.letsencrypt.org/directory
    email: stokemubashir@gmail.com
    privateKeySecretRef:
      name: letsencrypt-nginx-cert
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

  depends_on = [
    helm_release.cert_manager
  ]
}