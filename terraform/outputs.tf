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

# ── Azadi ────────────────────────────────────────────────────
output "azadi_wif_provider" {
  description = "WIF_PROVIDER for azadi repo GitHub secrets"
  value       = module.apps.azadi_wif_provider
}

output "azadi_gcp_sa_email" {
  description = "GCP_SA_EMAIL for azadi repo GitHub secrets"
  value       = module.apps.azadi_gcp_sa_email
}

output "azadi_cloud_run_url" {
  description = "Azadi Cloud Run service URL"
  value       = module.apps.azadi_cloud_run_url
}

output "azadi_hosting_url" {
  description = "Azadi Firebase Hosting URL"
  value       = module.apps.azadi_hosting_url
}

output "azadi_firestore_db" {
  description = "Azadi Firestore database name"
  value       = module.apps.azadi_firestore_db
}

# ── Azadi Go ────────────────────────────────────────────────
output "azadi_go_wif_provider" {
  description = "WIF_PROVIDER for azadi-go repo GitHub secrets"
  value       = module.apps.azadi_go_wif_provider
}

output "azadi_go_gcp_sa_email" {
  description = "GCP_SA_EMAIL for azadi-go repo GitHub secrets"
  value       = module.apps.azadi_go_gcp_sa_email
}

output "azadi_go_cloud_run_url" {
  description = "Azadi Go Cloud Run service URL"
  value       = module.apps.azadi_go_cloud_run_url
}

output "azadi_go_hosting_url" {
  description = "Azadi Go Firebase Hosting URL"
  value       = module.apps.azadi_go_hosting_url
}

output "azadi_go_firestore_db" {
  description = "Azadi Go Firestore database name"
  value       = module.apps.azadi_go_firestore_db
}

# ── OpenGuessr ──────────────────────────────────────────────
output "openguessr_wif_provider" {
  description = "WIF_PROVIDER for openguessr repo GitHub secrets"
  value       = module.apps.openguessr_wif_provider
}

output "openguessr_gcp_sa_email" {
  description = "GCP_SA_EMAIL for openguessr repo GitHub secrets"
  value       = module.apps.openguessr_gcp_sa_email
}

output "openguessr_hosting_url" {
  description = "OpenGuessr Firebase Hosting URL"
  value       = module.apps.openguessr_hosting_url
}