# ─────────────────────────────────────────────────────────────
# Shared Outputs
# ─────────────────────────────────────────────────────────────
output "project_id" {
  description = "GCP project ID"
  value       = var.project_id
}

output "project_number" {
  description = "GCP project number"
  value       = data.google_project.project.number
}

output "wif_pool_name" {
  description = "Workload Identity Pool full resource name"
  value       = module.wif_pool.pool_name
}

output "artifact_registry_url" {
  description = "Artifact Registry URL"
  value       = module.artifact_registry.url
}

# ─────────────────────────────────────────────────────────────
# Per-App Outputs (from apps module)
# ─────────────────────────────────────────────────────────────
output "hooklab_wif_provider" {
  description = "WIF_PROVIDER for webhook repo GitHub secrets"
  value       = module.apps.hooklab_wif_provider
}

output "hooklab_gcp_sa_email" {
  description = "GCP_SA_EMAIL for webhook repo GitHub secrets"
  value       = module.apps.hooklab_gcp_sa_email
}

output "hooklab_cloud_run_url" {
  description = "Cloud Run service URL"
  value       = module.apps.hooklab_cloud_run_url
}

output "hooklab_hosting_url" {
  description = "Firebase Hosting URL"
  value       = module.apps.hooklab_hosting_url
}

output "hooklab_firestore_db" {
  description = "Firestore database name"
  value       = module.apps.hooklab_firestore_db
}
