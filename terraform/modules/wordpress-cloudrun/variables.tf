variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for the service, bucket, and scheduler"
  type        = string
}

variable "app_name" {
  description = "Short app identifier; used for the Cloud Run service, SA names, secret prefixes, and bucket name"
  type        = string
}

variable "github_org" {
  description = "GitHub org or user that owns the app repo"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name that deploys this app"
  type        = string
}

variable "database_name" {
  description = "MySQL database name provisioned on the shared OCI HeatWave cluster"
  type        = string
}

variable "wif_pool_id" {
  description = "Shared Workload Identity Pool ID"
  type        = string
}

variable "wif_pool_name" {
  description = "Shared Workload Identity Pool full resource name"
  type        = string
}

variable "image" {
  description = "Container image; CI/CD swaps in the real image after the first deploy"
  type        = string
  default     = "gcr.io/cloudrun/hello"
}

variable "cpu" {
  type    = string
  default = "1"
}

variable "memory" {
  type    = string
  default = "1Gi"
}

variable "min_instances" {
  type    = number
  default = 0
}

variable "max_instances" {
  type    = number
  default = 1
}

variable "concurrency" {
  description = "Requests per instance; match the container's PHP worker/thread count"
  type        = number
  default     = 8
}

variable "cron_schedule" {
  description = "Cloud Scheduler cron for wp-cron.php; UTC"
  type        = string
  default     = "0 * * * *"
}

variable "public_uploads" {
  description = "Grant allUsers read on the uploads bucket so media serves directly from GCS"
  type        = bool
  default     = true
}

variable "extra_runtime_roles" {
  description = "Additional IAM roles for the runtime service account"
  type        = list(string)
  default     = []
}

variable "extra_env" {
  description = "Additional plain (non-secret) environment variables for the container"
  type        = map(string)
  default     = {}
}

variable "startup_probe_path" {
  description = "PHP-served path polled every second until it answers; a TCP probe passes while FrankenPHP can still swallow the first request"
  type        = string
  default     = "/wp-includes/version.php"
}
