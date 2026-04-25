variable "app_name" {
  type        = string
  description = "App name; used as prefix for GSM secret IDs (e.g. shehryar-db-user) and as the catalog map key"
}

variable "database_name" {
  type        = string
  description = "MySQL database name to provision for this app on the OCI MySQL HeatWave cluster"
}

variable "runtime_sa_email" {
  type        = string
  description = "Email of the runtime service account that will read the per-app DB secrets at runtime"
}

variable "project_id" {
  type        = string
  description = "GCP project ID hosting the secrets"
}
