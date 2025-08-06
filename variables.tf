variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "bookwork-466915"
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone within the region"
  type        = string
  default     = "us-central1-c"
}

variable "project" {
  description = "Project name prefix for resources"
  type        = string
  default     = "bookwork"
}

variable "domain_name" {
  description = "Domain name for SSL certificate"
  type        = string
  default     = "bookwork-demo.com"
}
