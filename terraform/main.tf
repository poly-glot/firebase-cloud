# ─────────────────────────────────────────────────────────────
# Firebase-Cloud — Shared GCP/Firebase Infrastructure
# ─────────────────────────────────────────────────────────────
# Central infrastructure repo that provisions:
#   - GCP Project with Firebase enabled
#   - Shared Workload Identity Pool (one pool, per-app providers)
#   - Per-app service accounts, WIF providers, IAM bindings
#   - Per-app Firestore named databases
#   - Firebase Hosting sites
#   - Artifact Registry
#   - Cloud Run services
#   - BigQuery datasets
#
# App repos (webhook, app-two, etc.) contain NO terraform —
# they consume outputs from this repo via GitHub secrets.
# ─────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.0"
    }
  }

  # ── Remote State ────────────────────────────────────────────
  backend "gcs" {
     bucket = "firebase-cloud-491613-tf-state"
     prefix = "terraform/state"
  }
}

# ─────────────────────────────────────────────────────────────
# Providers
# ─────────────────────────────────────────────────────────────
provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project                     = var.project_id
  region                      = var.region
  user_project_override       = true
  billing_project             = var.project_id
}

# ─────────────────────────────────────────────────────────────
# Data Sources
# ─────────────────────────────────────────────────────────────
data "google_project" "project" {
  project_id = var.project_id
}

# ─────────────────────────────────────────────────────────────
# Project Setup (APIs + Firebase)
# ─────────────────────────────────────────────────────────────
module "project_setup" {
  source = "./modules/project-setup"

  project_id = var.project_id
  region     = var.region
}

# ─────────────────────────────────────────────────────────────
# Shared Workload Identity Pool (ONE pool for all apps)
# ─────────────────────────────────────────────────────────────
module "wif_pool" {
  source = "./modules/wif-pool"

  project_id = var.project_id

  depends_on = [module.project_setup]
}

# ─────────────────────────────────────────────────────────────
# Shared Artifact Registry
# ─────────────────────────────────────────────────────────────
module "artifact_registry" {
  source = "./modules/artifact-registry"

  project_id = var.project_id
  region     = var.region
  repo_id    = var.ar_repo

  depends_on = [module.project_setup]
}

# ─────────────────────────────────────────────────────────────
# Per-App Modules (defined in apps/)
# ─────────────────────────────────────────────────────────────
module "apps" {
  source = "./apps"

  project_id     = var.project_id
  region         = var.region
  github_org     = var.github_org
  wif_pool_id    = module.wif_pool.pool_id
  wif_pool_name  = module.wif_pool.pool_name
  resend_api_key = var.resend_api_key

  depends_on = [module.project_setup]
}
