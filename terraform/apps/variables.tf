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

variable "azadi_stripe_api_key" {
  description = "Stripe secret API key for Azadi"
  type        = string
  sensitive   = true
}

variable "azadi_stripe_webhook_secret" {
  description = "Stripe webhook signing secret for Azadi"
  type        = string
  sensitive   = true
}

variable "azadi_stripe_publishable_key" {
  description = "Stripe publishable key for Azadi frontend"
  type        = string
  sensitive   = true
}

variable "azadi_encryption_key" {
  description = "AES encryption key for Azadi bank details"
  type        = string
  sensitive   = true
}

variable "azadi_encryption_salt" {
  description = "Hex-encoded salt for Azadi bank details encryption"
  type        = string
  sensitive   = true
}
