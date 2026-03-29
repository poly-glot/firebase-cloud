variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "database_name" {
  description = "Firestore database name (use app name, e.g. 'hooklab')"
  type        = string
}
