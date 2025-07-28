resource "helm_release" "dev-kong" {
  name             = "kong"
  repository       = "https://charts.konghq.com"
  chart            = "kong"
  namespace        = var.namespace
  create_namespace = true
  version          = "2.29.0"

  values = [
    yamlencode({
      ingressController = {
        enabled = true
      }
    })
  ]
}

