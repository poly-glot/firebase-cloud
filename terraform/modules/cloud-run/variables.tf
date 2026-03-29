variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "service_name" {
  description = "Cloud Run service name"
  type        = string
}

variable "image" {
  description = "Container image (updated by CI/CD after initial deploy)"
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "service_account_email" {
  description = "Runtime service account email"
  type        = string
}

variable "min_instances" {
  type    = number
  default = 0
}

variable "max_instances" {
  type    = number
  default = 10
}

variable "cpu" {
  type    = string
  default = "1"
}

variable "memory" {
  type    = string
  default = "512Mi"
}

variable "env_vars" {
  type    = map(string)
  default = {}
}

variable "health_path" {
  description = "HTTP path for startup/liveness probes"
  type        = string
  default     = "/api/health"
}

variable "allow_unauthenticated" {
  description = "Allow public access to the service"
  type        = bool
  default     = true
}
