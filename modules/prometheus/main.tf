resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = var.namespace
  create_namespace = true
  version          = "60.0.2"
}

variable "namespace" {
  description = "Namespace to install Prometheus"
  type        = string
  default     = "monitoring"
}
