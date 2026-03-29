# ─────────────────────────────────────────────────────────────
# Hooklab (webhook repo) — App Configuration
# ─────────────────────────────────────────────────────────────

# ── Identity: SA + WIF Provider ─────────────────────────────
module "hooklab_identity" {
  source = "../modules/app-identity"

  project_id    = var.project_id
  app_name      = "hooklab"
  github_org    = var.github_org
  github_repo   = "webhook"
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

  env_vars = {
    GCP_PROJECT      = var.project_id
    ALLOWED_ORIGINS  = "https://hooklab.web.app,https://hooklab.junaid.guru"
    BQ_DATASET       = "hooklab"
    BQ_TABLE         = "executions"
    GEMINI_MODEL     = "gemini-2.0-flash"
    VERTEX_AI_LOCATION = var.region
  }

  depends_on = [module.hooklab_identity]
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

