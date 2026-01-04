##6 External DNS

resource "kubectl_manifest" "external_dns_namespace" {
  yaml_body = <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: external-dns
EOF
}


resource "kubernetes_service_account_v1" "external_dns" {
  metadata {
    name      = "external-dns"
    namespace = "external-dns"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.external_dns.arn
    }
  }
    depends_on = [kubectl_manifest.external_dns_namespace] 
}


#resource "helm_release" "external_dns" {
 # name             = "external-dns"
 ## namespace        = "external-dns"
  #create_namespace = false
  #repository       = "https://kubernetes-sigs.github.io/external-dns/"
  #chart            = "external-dns"
  #version          = "1.14.0"

  #wait    = true
  #timeout = 600

 # set = [
   # {
    #  name  = "provider"
    #  value = "aws"
   # },
   # {
   #   name  = "aws.region"
   #   value = "eu-west-2"
   # },
   # {
   #   name  = "serviceAccount.create"
   #   value = "false"
   # },
   # {
    #  name  = "serviceAccount.name"
    #  value = "external-dns"
   # },
   # {
    #  name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    #  value = aws_iam_role.external_dns.arn
   # }
  #]

  #depends_on = [
  #  kubectl_manifest.external_dns_namespace,
   # kubernetes_service_account_v1.external_dns,
   # aws_iam_role.external_dns,
   # aws_iam_role_policy.external_dns_route53
  #]
#}
