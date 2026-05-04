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

# ── Amazing Landing ─────────────────────────────────────────
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

# ── OpenGuessr ──────────────────────────────────────────────
variable "openguessr_google_maps_api_key" {
  description = "Google Maps API key for OpenGuessr Street View"
  type        = string
  sensitive   = true
}

# ── Cross-stack: personal-cloud (OCI MySQL provisioning) ────
variable "personal_cloud_deploy_sa" {
  description = "personal-cloud workflow's deploy SA email; granted reader on bootstrap GSM secrets so it can authenticate to OCI tfstate and read MySQL admin creds"
  type        = string
}

# ─────────────────────────────────────────────────────────────
# Mocktail (and future cross-app shared keys)
# ─────────────────────────────────────────────────────────────
variable "unsplash_access_key" {
  description = "Unsplash Access Key (shared)"
  type        = string
  sensitive   = true
}

variable "gemini_api_key" {
  description = "Gemini API key (shared)"
  type        = string
  sensitive   = true
}
