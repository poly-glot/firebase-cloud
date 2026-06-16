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

variable "startup_probe" {
  description = "Startup-probe schedule. Defaults preserve the original behaviour; override per-app to tune cold-start readiness."
  type = object({
    initial_delay_seconds = number
    period_seconds        = number
    failure_threshold     = number
    timeout_seconds       = number
  })
  default = {
    initial_delay_seconds = 5
    period_seconds        = 10
    failure_threshold     = 3
    timeout_seconds       = 3
  }
}

variable "allow_unauthenticated" {
  description = "Allow public access to the service"
  type        = bool
  default     = true
}
