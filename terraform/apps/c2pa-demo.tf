# ─────────────────────────────────────────────────────────────
# C2PA Demo — Content Credentials Signing Demo
# ─────────────────────────────────────────────────────────────
# Node 22 HTTP server that generates images through the LLM
# gateway and signs them with a native c2pa library. Firebase
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
# Hosting forwards no cookie except __session, so the app's
# password session cookie must use that name. firebase.json in
# the app repo rewrites ** to the service.
module "c2pa_demo_hosting" {
  source = "../modules/hosting"

  project_id = var.project_id
  site_id    = "c2pa-demo"
}

# ── Secrets (shells only; add a version with `gcloud secrets versions add` before the first apply) ──

locals {
  c2pa_demo_secrets = {
    APP_PASSWORD = "c2pa-demo-app-password"
    LLM_API_KEY  = "c2pa-demo-llm-api-key"
    C2PA_KEY_PEM = "c2pa-demo-signer-key"
  }

  c2pa_demo_env = {
    LLM_GATEWAY_URL = "https://ai.europe-west1.storyteq.dev"
    LLM_IMAGE_MODEL = "gemini-3.1-flash-image"
    C2PA_CERT       = "cert/claim-signer.pem"
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

  depends_on = [module.c2pa_demo_identity, google_secret_manager_secret.c2pa_demo]
}

# ── Custom domain: c2pa-demo.junaid.guru ────────────────────
resource "google_firebase_hosting_custom_domain" "c2pa_demo" {
  provider      = google-beta
  project       = var.project_id
  site_id       = module.c2pa_demo_hosting.site_id
  custom_domain = "c2pa-demo.junaid.guru"

  wait_dns_verification = false
}
