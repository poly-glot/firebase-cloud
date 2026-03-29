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
  wif_pool_id   = module.wif_pool.pool_id
  wif_pool_name = module.wif_pool.pool_name
}

# ── Firestore: Named Database ──────────────────────────────
module "hooklab_firestore" {
  source = "../modules/firestore-databases"

  project_id    = var.project_id
  region        = var.region
  database_name = "hooklab"

  depends_on = [module.project_setup]
}

# ── Firebase Hosting ────────────────────────────────────────
module "hooklab_hosting" {
  source = "../modules/hosting"

  project_id = var.project_id
  site_id    = var.project_id # or a custom site ID

  depends_on = [module.project_setup]
}

# ── Cloud Run ───────────────────────────────────────────────
module "hooklab_cloud_run" {
  source = "../modules/cloud-run"

  project_id            = var.project_id
  region                = var.region
  service_name          = "hooklab-api"
  service_account_email = module.hooklab_identity.runtime_sa_email

  env_vars = {
    PORT = "8080"
  }

  depends_on = [module.project_setup, module.hooklab_identity]
}

# ── BigQuery ────────────────────────────────────────────────
module "hooklab_bigquery" {
  source = "../modules/bigquery"

  project_id       = var.project_id
  region           = var.region
  app_name         = "hooklab"
  dataset_id       = "hooklab"
  runtime_sa_email = module.hooklab_identity.runtime_sa_email

  depends_on = [module.project_setup, module.hooklab_identity]
}

# ─────────────────────────────────────────────────────────────
# Outputs — copy these into the webhook repo's GitHub secrets
# ─────────────────────────────────────────────────────────────
output "hooklab_wif_provider" {
  description = "WIF_PROVIDER for webhook repo GitHub secrets"
  value       = module.hooklab_identity.wif_provider
}

output "hooklab_gcp_sa_email" {
  description = "GCP_SA_EMAIL for webhook repo GitHub secrets"
  value       = module.hooklab_identity.ci_cd_sa_email
}

output "hooklab_cloud_run_url" {
  description = "Cloud Run service URL"
  value       = module.hooklab_cloud_run.service_url
}

output "hooklab_hosting_url" {
  description = "Firebase Hosting URL"
  value       = module.hooklab_hosting.site_url
}

output "hooklab_firestore_db" {
  description = "Firestore database name"
  value       = module.hooklab_firestore.database_name
}
