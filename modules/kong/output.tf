output "kong_proxy_service" {
  description = "Kong proxy service"
  value       = helm_release.kong.name
}
