variable "kong_chart_version" {
  description = "Kong Helm chart version"
  type        = string
  default     = "2.24.0"
}

variable "service_type" {
  description = "Kong service type (LoadBalancer, NodePort, etc.)"
  type        = string
  default     = "LoadBalancer"
}
