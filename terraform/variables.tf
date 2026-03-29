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
