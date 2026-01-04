variable "cert_issuer" {
  description = "Which lets encrypt clusterissuer to use"
  type = string
  default = "letsencrypt-prod"
}