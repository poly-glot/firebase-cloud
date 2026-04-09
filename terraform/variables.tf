# ─────────────────────────────────────────────────────────────
# Project-Level Variables
# ─────────────────────────────────────────────────────────────
variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for all resources"
  type        = string
  default     = "us-central1"
}

variable "ar_repo" {
  description = "Shared Artifact Registry repository ID"
  type        = string
  default     = "firebase-cloud"
}

# ─────────────────────────────────────────────────────────────
# GitHub (used by app-identity modules)
# ─────────────────────────────────────────────────────────────
variable "github_org" {
  description = "GitHub org or username that owns app repos"
  type        = string
}

# ─────────────────────────────────────────────────────────────
# Secrets (passed to app modules)
# ─────────────────────────────────────────────────────────────
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

# ─────────────────────────────────────────────────────────────
# Amazing Landing Secrets
# ─────────────────────────────────────────────────────────────
variable "amazing_landing_encryption_key" {
  description = "AES encryption key for Amazing Landing session cookies"
  type        = string
  sensitive   = true
}

variable "amazing_landing_admin_password_hash" {
  description = "Bcrypt password hash for the Amazing Landing admin user"
  type        = string
  sensitive   = true
}

# ─────────────────────────────────────────────────────────────
# OpenGuessr Secrets
# ─────────────────────────────────────────────────────────────
variable "openguessr_google_maps_api_key" {
  description = "Google Maps API key for OpenGuessr Street View"
  type        = string
  sensitive   = true
}
