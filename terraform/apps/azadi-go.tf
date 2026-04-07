# ─────────────────────────────────────────────────────────────
# Azadi Finance Portal (Go)
# ─────────────────────────────────────────────────────────────
# Go rewrite of the Azadi customer portal. Uses separate
# Firebase Hosting site, Cloud Run service, and Firestore DB
# to avoid conflicts with the Java application.
# ─────────────────────────────────────────────────────────────

module "azadi_go_identity" {
  source = "../modules/app-identity"

  project_id    = var.project_id
  app_name      = "azadi-go"
  github_org    = var.github_org
  github_repo   = "azadi-go"
  wif_pool_id   = var.wif_pool_id
  wif_pool_name = var.wif_pool_name

  runtime_roles = [
    "roles/datastore.user",
    "roles/secretmanager.secretAccessor",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/cloudtrace.agent",
  ]
}

module "azadi_go_firestore" {
  source = "../modules/firestore-databases"

  project_id    = var.project_id
  region        = var.region
  database_name = "azadi-go"
  database_type = "DATASTORE_MODE"
}

module "azadi_go_hosting" {
  source = "../modules/hosting"

  project_id = var.project_id
  site_id    = "azadi-go"
}

module "azadi_go_cloud_run" {
  source = "../modules/cloud-run"

  project_id            = var.project_id
  region                = var.region
  service_name          = "azadi-go-api"
  service_account_email = module.azadi_go_identity.runtime_sa_email
  memory                = "512Mi"
  health_path           = "/health"

  env_vars = {
    GCP_PROJECT_ID              = var.project_id
    FIRESTORE_DB                = "azadi-go"
    ENVIRONMENT                 = "production"
    SEED_DATA                   = "true"
    ALLOWED_ORIGINS             = "https://azadi-go.web.app"
    RESEND_FROM_EMAIL           = "noreply@junaid.guru"
    APP_DOMAIN                  = "azadi-go.web.app"
    RESEND_API_KEY              = var.resend_api_key
    STRIPE_API_KEY              = var.azadi_stripe_api_key
    STRIPE_WEBHOOK_SECRET       = var.azadi_stripe_webhook_secret
    VITE_STRIPE_PUBLISHABLE_KEY = var.azadi_stripe_publishable_key
    AZADI_ENCRYPTION_KEY        = var.azadi_encryption_key
    AZADI_ENCRYPTION_SALT       = var.azadi_encryption_salt
  }

  depends_on = [module.azadi_go_identity]
}