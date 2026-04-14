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

# ── Amazing Landing ─────────────────────────────────────────
output "amazing_landing_wif_provider" {
  description = "WIF_PROVIDER for amazing-landing repo GitHub secrets"
  value       = module.apps.amazing_landing_wif_provider
}

output "amazing_landing_gcp_sa_email" {
  description = "GCP_SA_EMAIL for amazing-landing repo GitHub secrets"
  value       = module.apps.amazing_landing_gcp_sa_email
}

output "amazing_landing_cloud_run_url" {
  description = "Amazing Landing Cloud Run service URL"
  value       = module.apps.amazing_landing_cloud_run_url
}

output "amazing_landing_hosting_url" {
  description = "Amazing Landing Firebase Hosting URL"
  value       = module.apps.amazing_landing_hosting_url
}

output "amazing_landing_firestore_db" {
  description = "Amazing Landing Firestore database name"
  value       = module.apps.amazing_landing_firestore_db
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
# ── amazingcar-2003 ─────────────────────────────────────────
output "amazingcar_2003_wif_provider" {
  description = "WIF_PROVIDER for amazingcar-2003 repo GitHub secrets"
  value       = module.apps.amazingcar_2003_wif_provider
}

output "amazingcar_2003_gcp_sa_email" {
  description = "GCP_SA_EMAIL for amazingcar-2003 repo GitHub secrets"
  value       = module.apps.amazingcar_2003_gcp_sa_email
}

output "amazingcar_2003_hosting_url" {
  description = "amazingcar-2003 Firebase Hosting URL"
  value       = module.apps.amazingcar_2003_hosting_url
}

output "amazingcar_2003_custom_domain" {
  description = "amazingcar-2003 custom domain"
  value       = module.apps.amazingcar_2003_custom_domain
}

output "amazingcar_2003_required_dns" {
  description = "DNS records required at the registrar to verify and serve the amazingcar-2003 custom domain"
  value       = module.apps.amazingcar_2003_required_dns
}

# ── pakistan-2003 ───────────────────────────────────────────
output "pakistan_2003_wif_provider" {
  description = "WIF_PROVIDER for pakistan-2003 repo GitHub secrets"
  value       = module.apps.pakistan_2003_wif_provider
}

output "pakistan_2003_gcp_sa_email" {
  description = "GCP_SA_EMAIL for pakistan-2003 repo GitHub secrets"
  value       = module.apps.pakistan_2003_gcp_sa_email
}

output "pakistan_2003_hosting_url" {
  description = "pakistan-2003 Firebase Hosting URL"
  value       = module.apps.pakistan_2003_hosting_url
}

output "pakistan_2003_custom_domain" {
  description = "pakistan-2003 custom domain"
  value       = module.apps.pakistan_2003_custom_domain
}

output "pakistan_2003_required_dns" {
  description = "DNS records required at the registrar to verify and serve the pakistan-2003 custom domain"
  value       = module.apps.pakistan_2003_required_dns
}
