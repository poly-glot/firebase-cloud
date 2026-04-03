# ─────────────────────────────────────────────────────────────
# Azadi Finance Portal
# ─────────────────────────────────────────────────────────────
# Customer finance agreement portal with Stripe payments,
# Firestore in Datastore mode, and Firebase Hosting.
# ─────────────────────────────────────────────────────────────

module "azadi_identity" {
  source = "../modules/app-identity"

  project_id    = var.project_id
  app_name      = "azadi"
  github_org    = var.github_org
  github_repo   = "azadi"
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

module "azadi_firestore" {
  source = "../modules/firestore-databases"

  project_id    = var.project_id
  region        = var.region
  database_name = "azadi"
  database_type = "DATASTORE_MODE"

}

module "azadi_hosting" {
  source = "../modules/hosting"

  project_id = var.project_id
  site_id    = "azadi"

}

module "azadi_cloud_run" {
  source = "../modules/cloud-run"

  project_id            = var.project_id
  region                = var.region
  service_name          = "azadi-api"
  service_account_email = module.azadi_identity.runtime_sa_email
  memory                = "1Gi"

  env_vars = {
    GCP_PROJECT                = var.project_id
    FIRESTORE_DB               = "azadi"
    ALLOWED_ORIGINS            = "https://azadi.web.app,https://azadi.junaid.guru"
    RESEND_FROM_EMAIL          = "noreply@junaid.guru"
    APP_DOMAIN                 = "azadi.junaid.guru"
    RESEND_API_KEY             = var.resend_api_key
    STRIPE_API_KEY             = var.azadi_stripe_api_key
    STRIPE_WEBHOOK_SECRET      = var.azadi_stripe_webhook_secret
    VITE_STRIPE_PUBLISHABLE_KEY = var.azadi_stripe_publishable_key
    AZADI_ENCRYPTION_KEY       = var.azadi_encryption_key
    AZADI_ENCRYPTION_SALT      = var.azadi_encryption_salt
  }

  depends_on = [module.azadi_identity]
}

module "azadi_scheduler" {
  source = "../modules/cloud-scheduler"

  project_id            = var.project_id
  region                = var.region
  service_account_email = module.azadi_identity.runtime_sa_email

  jobs = {
    azadi-settlement-cleanup = {
      schedule    = "0 2 * * *"
      uri         = "${module.azadi_cloud_run.service_url}/api/internal/cleanup"
      description = "Daily cleanup of expired settlement figures"
    }
  }

  depends_on = [module.azadi_cloud_run]
}