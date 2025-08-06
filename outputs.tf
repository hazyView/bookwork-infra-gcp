/*
output "load_balancer_ip" {
  description = "The IP address of the load balancer"
  value       = google_compute_global_address.default.address
}

output "domain_name" {
  description = "The domain name configured for the application"
  value       = var.domain_name
}

/* output "api_service_url" {
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

/* output "ssl_certificate_status" {
  description = "The status of the managed SSL certificate"
  value       = google_compute_managed_ssl_certificate.bookwork_ssl.self_link
} 

output "dns_instructions" {
  description = "DNS configuration instructions"
  value       = "Create an A record for ${var.domain_name} pointing to ${google_compute_global_address.default.address}"
}
*/
output "gke_cluster_name" {
  description = "Name of GKE Cluster"
  value = google_container_cluster.primary.name
}

output "gke_cluster_endpint" {
  description = "Endpoint for GKE cluster's master"
  value = google_container_cluster.primary.endpoint
  sensitive = true
}

output "gke_node_service_account" {
  description = "Email of service account used by GKE nodes"
  value = google_service_account.gke_node_sa.email
}

output "artifact_registry_name" {
  description = "Name of Artifact Registry"
  value = google_artifact_registry_repository.registry.name
}

output "network_name" {
  description = "Name of VPC network"
  value = google_compute_network.vpc.name
}

