resource "helm_release" "eks-kong" {
  name             = "king-kong"
  namespace        = "kong"
  create_namespace = true

  repository = "https://charts.konghq.com"
  chart      = "kong"
  version    = var.kong_chart_version

  values = [
    file("${path.module}/values/kong-values.yaml")
  ]

  set {
    name  = "ingressController.installCRDs"
    value = "true"
  }

  set {
    name  = "proxy.type"
    value = var.service_type
  }
}