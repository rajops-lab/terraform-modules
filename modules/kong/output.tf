output "kong_release_status" {
  description = "Kong Helm release status"
  value       = helm_release.dev-kong.status
}