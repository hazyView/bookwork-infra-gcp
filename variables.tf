variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "project" {
  description = "Project name prefix for resources"
  type        = string
  default     = "bookwork"
}

variable "domain_name" {
  description = "Domain name for SSL certificate"
  type        = string
  default     = "bookwork.demo.com"
}

variable "api_image_tag" {
  description = "Docker image tag for API"
  type        = string
  default     = "latest"
}

variable "frontend_image_tag" {
  description = "Docker image tag for frontend"
  type        = string
  default     = "latest"
}

variable "zone" {
  description = "The GCP zone within the region"
  type        = string
  default     = "us-central1-a"
}
