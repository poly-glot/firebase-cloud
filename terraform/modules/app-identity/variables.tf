variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "app_name" {
  description = "Short app identifier (used in SA names, WIF provider ID)"
  type        = string
}

variable "github_org" {
  description = "GitHub org or username"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "wif_pool_id" {
  description = "Workload Identity Pool ID (short ID, not full resource name)"
  type        = string
}

variable "wif_pool_name" {
  description = "Workload Identity Pool full resource name"
  type        = string
}

variable "ci_cd_roles" {
  description = "IAM roles for the CI/CD service account"
  type        = set(string)
  default = [
    "roles/firebase.admin",
    "roles/run.admin",
    "roles/iam.serviceAccountUser",
    "roles/artifactregistry.writer",
    "roles/cloudbuild.builds.builder",
    "roles/firebasehosting.admin",
    "roles/secretmanager.secretAccessor",
    "roles/serviceusage.serviceUsageConsumer",
  ]
}

variable "runtime_roles" {
  description = "IAM roles for the runtime (Cloud Run) service account"
  type        = set(string)
  default = [
    "roles/datastore.user",
    "roles/secretmanager.secretAccessor",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/cloudtrace.agent",
  ]
}
