##Kyverno

resource "kubernetes_namespace" "kyverno" {
  metadata {
    name = "kyverno"
    labels = {
      "istio-injection" = "disabled"
    }
  }
}

resource "helm_release" "kyverno" {
  name            = "kyverno"
  namespace       = kubernetes_namespace.kyverno.metadata[0].name
  repository      = "https://kyverno.github.io/kyverno/"
  chart           = "kyverno"
  version         = "3.8.1"
  atomic          = true
  cleanup_on_fail = true
  wait            = true
  timeout         = 600

  values = [
    yamlencode(var.kyverno_values)
  ]

  depends_on = [
    var.cluster_endpoint
  ]
}