variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "BigQuery dataset location"
  type        = string
}

variable "app_name" {
  description = "App identifier"
  type        = string
}

variable "dataset_id" {
  description = "BigQuery dataset ID"
  type        = string
}

variable "runtime_sa_email" {
  description = "Runtime SA email for IAM bindings"
  type        = string
}
