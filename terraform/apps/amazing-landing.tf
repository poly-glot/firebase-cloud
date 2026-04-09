# ─────────────────────────────────────────────────────────────
# Amazing Landing — In-store Skincare Quiz Platform
# ─────────────────────────────────────────────────────────────
# Customer-facing quiz with admin CMS. Firebase Hosting serves
# static quiz pages; Cloud Run handles API, admin panel, and
# server-rendered templates. Datastore for persistence.
# ─────────────────────────────────────────────────────────────

module "amazing_landing_identity" {
  source = "../modules/app-identity"

  project_id    = var.project_id
  app_name      = "amazing-landing"
  github_org    = var.github_org
  github_repo   = "amazing-landing"
  wif_pool_id   = var.wif_pool_id
  wif_pool_name = var.wif_pool_name

  runtime_roles = [
    "roles/datastore.user",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/cloudtrace.agent",
  ]
}

module "amazing_landing_firestore" {
  source = "../modules/firestore-databases"

  project_id    = var.project_id
  region        = var.region
  database_name = "amazing-landing"
  database_type = "DATASTORE_MODE"
}

module "amazing_landing_hosting" {
  source = "../modules/hosting"

  project_id = var.project_id
  site_id    = "amazing-landing"
}

module "amazing_landing_cloud_run" {
  source = "../modules/cloud-run"

  project_id            = var.project_id
  region                = var.region
  service_name          = "amazing-landing-api"
  service_account_email = module.amazing_landing_identity.runtime_sa_email
  memory                = "512Mi"
  health_path           = "/health"

  env_vars = {
    GCP_PROJECT_ID      = var.project_id
    DATASTORE_DB        = "amazing-landing"
    ENVIRONMENT         = "production"
    SEED_DATA           = "true"
    DEMO_MODE           = "false"
    ADMIN_EMAIL         = "admin@azadi.com"
    ENCRYPTION_KEY      = var.amazing_landing_encryption_key
    ADMIN_PASSWORD_HASH = var.amazing_landing_admin_password_hash
  }

  depends_on = [module.amazing_landing_identity]
}
