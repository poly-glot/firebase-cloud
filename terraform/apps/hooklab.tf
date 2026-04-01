# ─────────────────────────────────────────────────────────────
# Hooklab (webhook repo) — App Configuration
# ─────────────────────────────────────────────────────────────

# ── Identity: SA + WIF Provider ─────────────────────────────
module "hooklab_identity" {
  source = "../modules/app-identity"

  project_id    = var.project_id
  app_name      = "hooklab"
  github_org    = var.github_org
  github_repo   = "hooklab"
  wif_pool_id   = var.wif_pool_id
  wif_pool_name = var.wif_pool_name

  runtime_roles = [
    "roles/datastore.user",
    "roles/secretmanager.secretAccessor",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/cloudtrace.agent",
    "roles/aiplatform.user",
    "roles/bigquery.jobUser",
    "roles/bigquery.dataViewer",
    "roles/firebaseauth.admin",
  ]
}

# ── Firestore: Named Database ──────────────────────────────
module "hooklab_firestore" {
  source = "../modules/firestore-databases"

  project_id    = var.project_id
  region        = var.region
  database_name = "hooklab"

}

# ── Firebase Hosting ────────────────────────────────────────
module "hooklab_hosting" {
  source = "../modules/hosting"

  project_id = var.project_id
  site_id    = "hooklab"

}

# ── Cloud Run ───────────────────────────────────────────────
module "hooklab_cloud_run" {
  source = "../modules/cloud-run"

  project_id            = var.project_id
  region                = var.region
  service_name          = "hooklab-api"
  service_account_email = module.hooklab_identity.runtime_sa_email
  image                 = "${var.region}-docker.pkg.dev/${var.project_id}/firebase-cloud/api:latest"

  env_vars = {
    GCP_PROJECT        = var.project_id
    FIRESTORE_DB       = "hooklab"
    ALLOWED_ORIGINS    = "https://hooklab.web.app,https://hooklab.junaid.guru"
    BQ_DATASET         = "hooklab"
    BQ_TABLE           = "executions"
    GEMINI_MODEL       = "gemini-2.5-flash"
    VERTEX_AI_LOCATION = "europe-west1"
    RESEND_API_KEY     = var.resend_api_key
    FROM_EMAIL         = "noreply@junaid.guru"
    APP_DOMAIN         = "hooklab.junaid.guru"
  }

  depends_on = [module.hooklab_identity]
}

# ── Cloud Scheduler ─────────────────────────────────────────
module "hooklab_scheduler" {
  source = "../modules/cloud-scheduler"

  project_id            = var.project_id
  region                = var.region
  service_account_email = module.hooklab_identity.runtime_sa_email

  jobs = {
    hooklab-cleanup = {
      schedule    = "0 3 * * *"
      uri         = "${module.hooklab_cloud_run.service_url}/api/internal/cleanup"
      description = "Daily cleanup of old executions and quota reset"
    }
    hooklab-aggregate = {
      schedule    = "0 * * * *"
      uri         = "${module.hooklab_cloud_run.service_url}/api/internal/aggregate"
      description = "Hourly analytics aggregation"
    }
  }

  depends_on = [module.hooklab_cloud_run]
}

# ── BigQuery ────────────────────────────────────────────────
module "hooklab_bigquery" {
  source = "../modules/bigquery"

  project_id       = var.project_id
  region           = var.region
  app_name         = "hooklab"
  dataset_id       = "hooklab"
  runtime_sa_email = module.hooklab_identity.runtime_sa_email

  depends_on = [module.hooklab_identity]
}

