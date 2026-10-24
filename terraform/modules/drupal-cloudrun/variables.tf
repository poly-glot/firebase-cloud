variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for the service, jobs, bucket and scheduler"
  type        = string
}

variable "app_name" {
  description = "Short app identifier; used for the Cloud Run service and jobs, SA names, secret prefixes and the files bucket"
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
  description = "Requests per instance; match the container's PHP thread count"
  type        = number
  default     = 8
}

variable "cron_schedule" {
  description = "Cloud Scheduler cron that executes the drush cron job; UTC"
  type        = string
  default     = "0 * * * *"
}

variable "startup_probe_path" {
  description = "PHP-served path polled every second until it answers; it must not bootstrap Drupal"
  type        = string
  default     = "/health.php"
}

variable "files_mount_path" {
  description = "Where the files bucket is mounted inside the containers; Drupal's public files directory"
  type        = string
  default     = "/app/web/sites/default/files"
}

variable "bootstrap_command" {
  description = "Arguments passed to the image entrypoint by the bootstrap job after every deploy: install or deploy, OAuth, seed"
  type        = list(string)
}

variable "cron_command" {
  description = "Arguments passed to the image entrypoint by the scheduled cron job"
  type        = list(string)
  default     = ["vendor/bin/drush", "cron", "--yes"]
}

variable "extra_runtime_roles" {
  description = "Additional IAM roles for the runtime service account"
  type        = list(string)
  default     = []
}

variable "extra_secret_env" {
  description = "Additional environment variables for the service and both jobs, as env name to Secret Manager secret id; the runtime account must already be able to read each secret"
  type        = map(string)
  default     = {}
}

variable "extra_env" {
  description = "Additional plain (non-secret) environment variables for the service and both jobs"
  type        = map(string)
  default     = {}
}

variable "warm_schedule" {
  description = "Cloud Scheduler cron that requests warm_path on the service so an instance stays up between visitors; UTC"
  type        = string
  default     = "*/15 * * * *"
}

variable "warm_path" {
  description = "Path requested by the warm ping; a full page so Twig, aggregates and caches are built"
  type        = string
  default     = "/"
}
