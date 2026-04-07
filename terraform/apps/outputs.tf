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

# ── Azadi Outputs ───────────────────────────────────────────
output "azadi_wif_provider" {
  description = "WIF_PROVIDER for azadi repo GitHub secrets"
  value       = module.azadi_identity.wif_provider
}

output "azadi_gcp_sa_email" {
  description = "GCP_SA_EMAIL for azadi repo GitHub secrets"
  value       = module.azadi_identity.ci_cd_sa_email
}

output "azadi_cloud_run_url" {
  description = "Azadi Cloud Run service URL"
  value       = module.azadi_cloud_run.service_url
}

output "azadi_hosting_url" {
  description = "Azadi Firebase Hosting URL"
  value       = module.azadi_hosting.site_url
}

output "azadi_firestore_db" {
  description = "Azadi Firestore database name"
  value       = module.azadi_firestore.database_name
}

# ── Azadi Go Outputs ───────────────────────────────────────
output "azadi_go_wif_provider" {
  description = "WIF_PROVIDER for azadi-go repo GitHub secrets"
  value       = module.azadi_go_identity.wif_provider
}

output "azadi_go_gcp_sa_email" {
  description = "GCP_SA_EMAIL for azadi-go repo GitHub secrets"
  value       = module.azadi_go_identity.ci_cd_sa_email
}

output "azadi_go_cloud_run_url" {
  description = "Azadi Go Cloud Run service URL"
  value       = module.azadi_go_cloud_run.service_url
}

output "azadi_go_hosting_url" {
  description = "Azadi Go Firebase Hosting URL"
  value       = module.azadi_go_hosting.site_url
}

output "azadi_go_firestore_db" {
  description = "Azadi Go Firestore database name"
  value       = module.azadi_go_firestore.database_name
}

# ── OpenGuessr Outputs ──────────────────────────────────────
output "openguessr_wif_provider" {
  description = "WIF_PROVIDER for openguessr repo GitHub secrets"
  value       = module.openguessr_identity.wif_provider
}

output "openguessr_gcp_sa_email" {
  description = "GCP_SA_EMAIL for openguessr repo GitHub secrets"
  value       = module.openguessr_identity.ci_cd_sa_email
}

output "openguessr_hosting_url" {
  description = "OpenGuessr Firebase Hosting URL"
  value       = module.openguessr_hosting.site_url
}

output "openguessr_rtdb_url" {
  description = "OpenGuessr Realtime Database URL"
  value       = "https://${google_firebase_database_instance.openguessr.instance_id}.${google_firebase_database_instance.openguessr.region}.firebasedatabase.app"
}

output "openguessr_maps_web_api_key" {
  description = "OpenGuessr referrer-restricted Maps Web API key (set as GitHub secret GOOGLE_MAPS_API_KEY)"
  value       = google_apikeys_key.openguessr_maps_web.key_string
  sensitive   = true
}