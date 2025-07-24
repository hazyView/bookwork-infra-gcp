# Enable required APIs
resource "google_project_service" "services" {
  for_each = toset([
    "run.googleapis.com",
    "containerregistry.googleapis.com",
    "artifactregistry.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "certificatemanager.googleapis.com"
  ])
  
  project = var.project_id
  service = each.value
  
  disable_dependent_services = true
  disable_on_destroy        = false
}

# Artifact Registry repository for container images
resource "google_artifact_registry_repository" "api" {
  project       = var.project_id
  location      = var.region
  repository_id = "${var.project}-api"
  description   = "Docker repository for ${var.project} API"
  format        = "DOCKER"
  
  depends_on = [google_project_service.services]
}

resource "google_artifact_registry_repository" "frontend" {
  project       = var.project_id
  location      = var.region
  repository_id = "${var.project}-frontend"
  description   = "Docker repository for ${var.project} frontend"
  format        = "DOCKER"
  
  depends_on = [google_project_service.services]
}

# Service Account for Cloud Run services
resource "google_service_account" "cloud_run" {
  project      = var.project_id
  account_id   = "${var.project}-cloud-run"
  display_name = "Cloud Run Service Account for ${var.project}"
  description  = "Service account used by Cloud Run services"
}

# IAM binding for Cloud Run service account
resource "google_project_iam_member" "cloud_run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}

# Cloud Run API service
resource "google_cloud_run_v2_service" "api" {
  project  = var.project_id
  name     = "${var.project}-api"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.cloud_run.email
    
    scaling {
      min_instance_count = 0
      max_instance_count = 10
    }
    
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.api.repository_id}/api:${var.api_image_tag}"
      
      ports {
        container_port = 8080
      }
      
      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
        cpu_idle = true
      }
      
      startup_probe {
        http_get {
          path = "/health"
          port = 8080
        }
        initial_delay_seconds = 10
        timeout_seconds       = 5
        period_seconds        = 10
        failure_threshold     = 3
      }
      
      liveness_probe {
        http_get {
          path = "/health"
          port = 8080
        }
        initial_delay_seconds = 30
        timeout_seconds       = 5
        period_seconds        = 30
        failure_threshold     = 3
      }
    }
  }
  
  depends_on = [google_project_service.services]
}

# Cloud Run frontend service
resource "google_cloud_run_v2_service" "frontend" {
  project  = var.project_id
  name     = "${var.project}-frontend"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.cloud_run.email
    
    scaling {
      min_instance_count = 0
      max_instance_count = 10
    }
    
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.frontend.repository_id}/frontend:${var.frontend_image_tag}"
      
      ports {
        container_port = 3000
      }
      
      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
        cpu_idle = true
      }
      
      startup_probe {
        http_get {
          path = "/"
          port = 3000
        }
        initial_delay_seconds = 10
        timeout_seconds       = 5
        period_seconds        = 10
        failure_threshold     = 3
      }
      
      liveness_probe {
        http_get {
          path = "/"
          port = 3000
        }
        initial_delay_seconds = 30
        timeout_seconds       = 5
        period_seconds        = 30
        failure_threshold     = 3
      }
    }
  }
  
  depends_on = [google_project_service.services]
}

# Allow unauthenticated invocations for both services
resource "google_cloud_run_service_iam_binding" "api_noauth" {
  project  = var.project_id
  location = google_cloud_run_v2_service.api.location
  service  = google_cloud_run_v2_service.api.name
  role     = "roles/run.invoker"
  members = [
    "allUsers"
  ]
}

resource "google_cloud_run_service_iam_binding" "frontend_noauth" {
  project  = var.project_id
  location = google_cloud_run_v2_service.frontend.location
  service  = google_cloud_run_v2_service.frontend.name
  role     = "roles/run.invoker"
  members = [
    "allUsers"
  ]
}

# Global IP address for the load balancer
resource "google_compute_global_address" "default" {
  project = var.project_id
  name    = "${var.project}-lb-ip"
}

# Google-managed SSL certificate
resource "google_compute_managed_ssl_certificate" "default" {
  project = var.project_id
  name    = "${var.project}-ssl-cert"

  managed {
    domains = [var.domain_name]
  }
}

# Backend service for API
resource "google_compute_backend_service" "api" {
  project             = var.project_id
  name                = "${var.project}-api-backend"
  port_name           = "http"
  protocol            = "HTTP"
  timeout_sec         = 30
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.api.id
  }

  health_checks = [google_compute_health_check.api.id]
}

# Backend service for frontend
resource "google_compute_backend_service" "frontend" {
  project             = var.project_id
  name                = "${var.project}-frontend-backend"
  port_name           = "http"
  protocol            = "HTTP"
  timeout_sec         = 30
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.frontend.id
  }

  health_checks = [google_compute_health_check.frontend.id]
}

# Network Endpoint Group for API service
resource "google_compute_region_network_endpoint_group" "api" {
  project               = var.project_id
  name                  = "${var.project}-api-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region

  cloud_run {
    service = google_cloud_run_v2_service.api.name
  }
}

# Network Endpoint Group for frontend service
resource "google_compute_region_network_endpoint_group" "frontend" {
  project               = var.project_id
  name                  = "${var.project}-frontend-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region

  cloud_run {
    service = google_cloud_run_v2_service.frontend.name
  }
}

# Health checks
resource "google_compute_health_check" "api" {
  project = var.project_id
  name    = "${var.project}-api-healthcheck"

  http_health_check {
    request_path = "/health"
    port         = 8080
  }

  check_interval_sec  = 30
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2
}

resource "google_compute_health_check" "frontend" {
  project = var.project_id
  name    = "${var.project}-frontend-healthcheck"

  http_health_check {
    request_path = "/"
    port         = 3000
  }

  check_interval_sec  = 30
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2
}

# URL map for the load balancer
resource "google_compute_url_map" "default" {
  project         = var.project_id
  name            = "${var.project}-urlmap"
  default_service = google_compute_backend_service.frontend.id

  host_rule {
    hosts        = [var.domain_name]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.frontend.id

    path_rule {
      paths   = ["/api/*"]
      service = google_compute_backend_service.api.id
    }
  }
}

# HTTP(S) target proxy
resource "google_compute_target_https_proxy" "default" {
  project          = var.project_id
  name             = "${var.project}-https-proxy"
  url_map          = google_compute_url_map.default.id
  ssl_certificates = [google_compute_managed_ssl_certificate.default.id]
}

# HTTP target proxy for redirect
resource "google_compute_target_http_proxy" "default" {
  project = var.project_id
  name    = "${var.project}-http-proxy"
  url_map = google_compute_url_map.redirect_to_https.id
}

# URL map for HTTP to HTTPS redirect
resource "google_compute_url_map" "redirect_to_https" {
  project = var.project_id
  name    = "${var.project}-redirect-urlmap"

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

# Global forwarding rule for HTTPS
resource "google_compute_global_forwarding_rule" "https" {
  project    = var.project_id
  name       = "${var.project}-https-forwarding-rule"
  target     = google_compute_target_https_proxy.default.id
  port_range = "443"
  ip_address = google_compute_global_address.default.address
}

# Global forwarding rule for HTTP (redirect to HTTPS)
resource "google_compute_global_forwarding_rule" "http" {
  project    = var.project_id
  name       = "${var.project}-http-forwarding-rule"
  target     = google_compute_target_http_proxy.default.id
  port_range = "80"
  ip_address = google_compute_global_address.default.address
}
