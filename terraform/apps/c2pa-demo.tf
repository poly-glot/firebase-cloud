# ─────────────────────────────────────────────────────────────
# C2PA Demo — Content Credentials Signing Demo
# ─────────────────────────────────────────────────────────────
# Node 22 HTTP server that generates and edits images on
# Hugging Face ZeroGPU Spaces (FLUX.1-schnell, FLUX.1 Kontext)
# and signs them with a native c2pa library. Firebase
# Hosting rewrites everything to Cloud Run; secrets live in
# Secret Manager and the app pipeline only moves images.
# ─────────────────────────────────────────────────────────────

module "c2pa_demo_identity" {
  source = "../modules/app-identity"

  project_id    = var.project_id
  app_name      = "c2pa-demo"
  github_org    = var.github_org
  github_repo   = "c2pa-demo"
  wif_pool_id   = var.wif_pool_id
  wif_pool_name = var.wif_pool_name

  runtime_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/cloudtrace.agent",
    "roles/secretmanager.secretAccessor",
  ]
}

# ── Firebase Hosting: c2pa-demo.web.app → Cloud Run ─────────
# firebase.json in the app repo rewrites ** to the service.
module "c2pa_demo_hosting" {
  source = "../modules/hosting"

  project_id = var.project_id
  site_id    = "c2pa-demo"
}

# ── Secrets ─────────────────────────────────────────────────
# Versions come from GitHub secrets through Terraform variables:
# HF_TOKEN from HF_TOKEN (var.hf_token), C2PA_KEY_PEM from
# C2PA_DEMO_SIGNER_KEY (var.c2pa_demo_signer_key). The key signs
# for cert/claim-signer.pem in the app repo; rotate them together.

locals {
  c2pa_demo_secrets = {
    HF_TOKEN     = "c2pa-demo-hf-token"
    C2PA_KEY_PEM = "c2pa-demo-signer-key"
  }

  c2pa_demo_retired_secrets = {
    APP_PASSWORD = "c2pa-demo-app-password"
    LLM_API_KEY  = "c2pa-demo-llm-api-key"
  }

  c2pa_demo_env = {
    C2PA_CERT = "cert/claim-signer.pem"
  }
}

resource "google_secret_manager_secret" "c2pa_demo" {
  for_each = local.c2pa_demo_secrets

  project   = var.project_id
  secret_id = each.value
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "c2pa_demo_hf_token" {
  secret      = google_secret_manager_secret.c2pa_demo["HF_TOKEN"].id
  secret_data = var.hf_token
}

resource "google_secret_manager_secret_version" "c2pa_demo_signer_key" {
  secret      = google_secret_manager_secret.c2pa_demo["C2PA_KEY_PEM"].id
  secret_data = var.c2pa_demo_signer_key
}

# Retired secrets: the LLM gateway key (replaced by ZeroGPU) and the
# app password (the demo is open). Neither is mounted any more; they
# are kept, not destroyed, so the values stay recoverable.
resource "google_secret_manager_secret" "c2pa_demo_retired" {
  for_each = local.c2pa_demo_retired_secrets

  project   = var.project_id
  secret_id = each.value
  replication {
    auto {}
  }
}

moved {
  from = google_secret_manager_secret.c2pa_demo_llm_api_key
  to   = google_secret_manager_secret.c2pa_demo_retired["LLM_API_KEY"]
}

moved {
  from = google_secret_manager_secret.c2pa_demo["APP_PASSWORD"]
  to   = google_secret_manager_secret.c2pa_demo_retired["APP_PASSWORD"]
}

# ── Cloud Run service ───────────────────────────────────────

module "c2pa_demo_cloud_run" {
  source = "../modules/cloud-run"

  project_id            = var.project_id
  region                = var.region
  service_name          = "c2pa-demo"
  service_account_email = module.c2pa_demo_identity.runtime_sa_email
  cpu                   = "1"
  memory                = "1Gi"
  max_instances         = 3
  health_path           = "/api/health"
  env_vars              = local.c2pa_demo_env
  secret_env_vars       = local.c2pa_demo_secrets

  depends_on = [
    module.c2pa_demo_identity,
    google_secret_manager_secret.c2pa_demo,
    google_secret_manager_secret_version.c2pa_demo_hf_token,
    google_secret_manager_secret_version.c2pa_demo_signer_key,
  ]
}

# ── Custom domain: c2pa-demo.junaid.guru ────────────────────
resource "google_firebase_hosting_custom_domain" "c2pa_demo" {
  provider      = google-beta
  project       = var.project_id
  site_id       = module.c2pa_demo_hosting.site_id
  custom_domain = "c2pa-demo.junaid.guru"

  wait_dns_verification = false
}
