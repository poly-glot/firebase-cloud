# ─────────────────────────────────────────────────────────────
# Hooklab Outputs
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
