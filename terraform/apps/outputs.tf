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

# ── Amazing Landing Outputs ─────────────────────────────────
output "amazing_landing_wif_provider" {
  description = "WIF_PROVIDER for amazing-landing repo GitHub secrets"
  value       = module.amazing_landing_identity.wif_provider
}

output "amazing_landing_gcp_sa_email" {
  description = "GCP_SA_EMAIL for amazing-landing repo GitHub secrets"
  value       = module.amazing_landing_identity.ci_cd_sa_email
}

output "amazing_landing_cloud_run_url" {
  description = "Amazing Landing Cloud Run service URL"
  value       = module.amazing_landing_cloud_run.service_url
}

output "amazing_landing_hosting_url" {
  description = "Amazing Landing Firebase Hosting URL"
  value       = module.amazing_landing_hosting.site_url
}

output "amazing_landing_firestore_db" {
  description = "Amazing Landing Firestore database name"
  value       = module.amazing_landing_firestore.database_name
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
# ── amazingcar-2003 Outputs ─────────────────────────────────
output "amazingcar_2003_wif_provider" {
  description = "WIF_PROVIDER for amazingcar-2003 repo GitHub secrets"
  value       = module.amazingcar_2003_identity.wif_provider
}

output "amazingcar_2003_gcp_sa_email" {
  description = "GCP_SA_EMAIL for amazingcar-2003 repo GitHub secrets"
  value       = module.amazingcar_2003_identity.ci_cd_sa_email
}

output "amazingcar_2003_hosting_url" {
  description = "Firebase Hosting URL"
  value       = module.amazingcar_2003_hosting.site_url
}

output "amazingcar_2003_custom_domain" {
  description = "Custom domain for amazingcar-2003"
  value       = google_firebase_hosting_custom_domain.amazingcar_2003.custom_domain
}

output "amazingcar_2003_required_dns" {
  description = "DNS records required at the registrar to verify and serve the custom domain"
  value       = google_firebase_hosting_custom_domain.amazingcar_2003.required_dns_updates
}
