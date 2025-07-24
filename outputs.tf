output "load_balancer_ip" {
  description = "The IP address of the load balancer"
  value       = google_compute_global_address.default.address
}

output "domain_name" {
  description = "The domain name configured for the application"
  value       = var.domain_name
}

output "api_service_url" {
  description = "The URL of the Cloud Run API service"
  value       = google_cloud_run_v2_service.api.uri
}

output "frontend_service_url" {
  description = "The URL of the Cloud Run frontend service"
  value       = google_cloud_run_v2_service.frontend.uri
}

output "api_artifact_registry_url" {
  description = "The Artifact Registry URL for the API repository"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.api.repository_id}"
}

output "frontend_artifact_registry_url" {
  description = "The Artifact Registry URL for the frontend repository"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.frontend.repository_id}"
}

output "ssl_certificate_status" {
  description = "The status of the managed SSL certificate"
  value       = google_compute_managed_ssl_certificate.default.managed[0].status
}

output "dns_instructions" {
  description = "DNS configuration instructions"
  value       = "Create an A record for ${var.domain_name} pointing to ${google_compute_global_address.default.address}"
}
