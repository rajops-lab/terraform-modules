 resource "helm_release" "eks_kong" {
  name             = "king-kong"
  namespace        = "kong"
  create_namespace = true

  repository = "https://charts.konghq.com"
  chart      = "kong"
  version    = var.kong_chart_version
  timeout    = 600
  dependency_update = true

  values = [
    file("${path.root}/${var.values_file_path}")
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