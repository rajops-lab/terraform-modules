output "grafana_url" {
  description = "Grafana endpoint URL"
  value       = helm_release.kube_prometheus_stack.name
}
