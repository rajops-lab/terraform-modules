output "grafana_release_status" {
  description = "Grafana Helm release status"
  value       = helm_release.kube_prometheus_stack.status
}