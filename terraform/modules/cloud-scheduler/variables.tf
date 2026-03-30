variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "jobs" {
  description = "Map of scheduler jobs to create"
  type = map(object({
    schedule    = string
    uri         = string
    http_method = optional(string, "POST")
    body        = optional(string, "")
    description = optional(string, "")
  }))
}

variable "service_account_email" {
  description = "Service account email for OIDC authentication"
  type        = string
}