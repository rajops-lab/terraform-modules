resource "helm_release" "grafana" {
  name             = "grafana"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  namespace        = var.namespace
  create_namespace = false   # Because monitoring ns is already made by Prometheus module
  version          = "8.0.0"

  set {
    name  = "adminPassword"
    value = var.admin_password
  }
}

variable "namespace" {
  description = "Namespace to install Grafana"
  type        = string
  default     = "monitoring"
}
variable "admin_password" {
  description = "Grafana admin password"
  type        = string
}

output "grafana_status" {
    value = helm_release.grafana.status
}