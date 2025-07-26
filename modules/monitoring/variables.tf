variable "prometheus_chart_version" {
  description = "Prometheus stack chart version"
  type        = string
  default     = "75.15.0"
}

variable "values_file_path" {
  description = "Path to monitoring-values.yaml from root"
  type        = string
}