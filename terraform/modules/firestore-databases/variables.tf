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

variable "database_type" {
  description = "Firestore database type: FIRESTORE_NATIVE or DATASTORE_MODE"
  type        = string
  default     = "FIRESTORE_NATIVE"
  validation {
    condition     = contains(["FIRESTORE_NATIVE", "DATASTORE_MODE"], var.database_type)
    error_message = "database_type must be FIRESTORE_NATIVE or DATASTORE_MODE"
  }
}