variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "github_org" {
  description = "GitHub org or username"
  type        = string
}

variable "wif_pool_id" {
  description = "Shared WIF pool ID"
  type        = string
}

variable "wif_pool_name" {
  description = "Shared WIF pool full resource name"
  type        = string
}

variable "resend_api_key" {
  description = "Resend API key for transactional emails"
  type        = string
  sensitive   = true
}
