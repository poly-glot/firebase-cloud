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

# ── pakistan-2003 Outputs ───────────────────────────────────
output "pakistan_2003_wif_provider" {
  description = "WIF_PROVIDER for pakistan-2003 repo GitHub secrets"
  value       = module.pakistan_2003_identity.wif_provider
}

output "pakistan_2003_gcp_sa_email" {
  description = "GCP_SA_EMAIL for pakistan-2003 repo GitHub secrets"
  value       = module.pakistan_2003_identity.ci_cd_sa_email
}

output "pakistan_2003_hosting_url" {
  description = "Firebase Hosting URL"
  value       = module.pakistan_2003_hosting.site_url
}

output "pakistan_2003_custom_domain" {
  description = "Custom domain for pakistan-2003"
  value       = google_firebase_hosting_custom_domain.pakistan_2003.custom_domain
}

output "pakistan_2003_required_dns" {
  description = "DNS records required at the registrar to verify and serve the custom domain"
  value       = google_firebase_hosting_custom_domain.pakistan_2003.required_dns_updates
}

# ── thehighlands Outputs ────────────────────────────────────
output "thehighlands_wif_provider" {
  description = "WIF_PROVIDER for thehighlands repo GitHub secrets"
  value       = module.thehighlands_identity.wif_provider
}

output "thehighlands_gcp_sa_email" {
  description = "GCP_SA_EMAIL for thehighlands repo GitHub secrets"
  value       = module.thehighlands_identity.ci_cd_sa_email
}

output "thehighlands_hosting_url" {
  description = "Firebase Hosting URL"
  value       = module.thehighlands_hosting.site_url
}

output "thehighlands_custom_domain" {
  description = "Custom domain for thehighlands"
  value       = google_firebase_hosting_custom_domain.thehighlands.custom_domain
}

output "thehighlands_required_dns" {
  description = "DNS records required at the registrar to verify and serve the custom domain"
  value       = google_firebase_hosting_custom_domain.thehighlands.required_dns_updates
}

# ── crea8ivedesign Outputs ──────────────────────────────────
output "crea8ivedesign_wif_provider" {
  description = "WIF_PROVIDER for crea8ivedesign repo GitHub secrets"
  value       = module.crea8ivedesign_identity.wif_provider
}

output "crea8ivedesign_gcp_sa_email" {
  description = "GCP_SA_EMAIL for crea8ivedesign repo GitHub secrets"
  value       = module.crea8ivedesign_identity.ci_cd_sa_email
}

output "crea8ivedesign_hosting_url" {
  description = "Firebase Hosting URL"
  value       = module.crea8ivedesign_hosting.site_url
}

output "crea8ivedesign_custom_domain" {
  description = "Custom domain for crea8ivedesign"
  value       = google_firebase_hosting_custom_domain.crea8ivedesign.custom_domain
}

output "crea8ivedesign_required_dns" {
  description = "DNS records required at the registrar to verify and serve the custom domain"
  value       = google_firebase_hosting_custom_domain.crea8ivedesign.required_dns_updates
}

# ── shehryar Outputs ────────────────────────────────────────
output "shehryar_wif_provider" {
  description = "WIF_PROVIDER for shehryar repo GitHub secrets"
  value       = module.shehryar_identity.wif_provider
}

output "shehryar_gcp_sa_email" {
  description = "GCP_SA_EMAIL for shehryar repo GitHub secrets"
  value       = module.shehryar_identity.ci_cd_sa_email
}

output "shehryar_hosting_url" {
  description = "Firebase Hosting URL"
  value       = module.shehryar_hosting.site_url
}

output "shehryar_custom_domain" {
  description = "Custom domain for shehryar"
  value       = google_firebase_hosting_custom_domain.shehryar.custom_domain
}

output "shehryar_required_dns" {
  description = "DNS records required at the registrar to verify and serve the custom domain"
  value       = google_firebase_hosting_custom_domain.shehryar.required_dns_updates
}

output "shehryar_api_url" {
  description = "Cloud Run URL for the shehryar chatapp backend"
  value       = google_cloud_run_v2_service.shehryar_api.uri
}

# ── Mocktail Outputs ────────────────────────────────────────
output "mocktail_wif_provider" {
  description = "WIF_PROVIDER for mocktail repo GitHub secrets"
  value       = module.mocktail_identity.wif_provider
}

output "mocktail_gcp_sa_email" {
  description = "GCP_SA_EMAIL for mocktail repo GitHub secrets"
  value       = module.mocktail_identity.ci_cd_sa_email
}

output "mocktail_runtime_sa_email" {
  description = "Mocktail runtime service account"
  value       = module.mocktail_identity.runtime_sa_email
}

output "mocktail_cloud_run_url" {
  description = "Cloud Run URL for the Zig collab service"
  value       = google_cloud_run_v2_service.mocktail.uri
}

output "mocktail_email_auth_url" {
  description = "Cloud Run URL for the Deno email-auth/AI service"
  value       = module.mocktail_email_auth_cloud_run.service_url
}

output "mocktail_hosting_url" {
  description = "Firebase Hosting URL"
  value       = module.mocktail_hosting.site_url
}

output "mocktail_firestore_db" {
  description = "Firestore database name"
  value       = module.mocktail_firestore.database_name
}

output "mocktail_custom_domain" {
  description = "Custom domain for mocktail"
  value       = google_firebase_hosting_custom_domain.mocktail.custom_domain
}

output "mocktail_required_dns" {
  description = "DNS records required at the registrar to verify and serve the custom domain"
  value       = google_firebase_hosting_custom_domain.mocktail.required_dns_updates
}

# ── Personal Site 2026 Outputs ──────────────────────────────
output "personal_site_2026_wif_provider" {
  description = "WIF_PROVIDER for personal-site-2026 repo GitHub secrets"
  value       = module.personal_site_identity.wif_provider
}

output "personal_site_2026_gcp_sa_email" {
  description = "GCP_SA_EMAIL for personal-site-2026 repo GitHub secrets"
  value       = module.personal_site_identity.ci_cd_sa_email
}

output "personal_site_2026_cloud_run_url" {
  description = "Cloud Run service URL"
  value       = module.personal_site_cloud_run.service_url
}

output "personal_site_2026_hosting_url" {
  description = "Firebase Hosting URL"
  value       = module.personal_site_hosting.site_url
}

output "personal_site_2026_custom_domains" {
  description = "Custom domains for personal-site-2026 (apex serves, www redirects)"
  value = {
    apex = google_firebase_hosting_custom_domain.personal_site_apex.custom_domain
    www  = google_firebase_hosting_custom_domain.personal_site_www.custom_domain
  }
}

output "personal_site_2026_required_dns" {
  description = "DNS records to add at the registrar for junaid.guru and www.junaid.guru"
  value = {
    apex = google_firebase_hosting_custom_domain.personal_site_apex.required_dns_updates
    www  = google_firebase_hosting_custom_domain.personal_site_www.required_dns_updates
  }
}

output "wordpress_sample_wif_provider" {
  description = "WIF_PROVIDER for wordpress-sample repo GitHub secrets"
  value       = module.wordpress_sample_identity.wif_provider
}

output "wordpress_sample_gcp_sa_email" {
  description = "GCP_SA_EMAIL for wordpress-sample repo GitHub secrets"
  value       = module.wordpress_sample_identity.ci_cd_sa_email
}

output "wordpress_sample_cloud_run_url" {
  description = "Cloud Run URL for wordpress-sample"
  value       = google_cloud_run_v2_service.wordpress_sample.uri
}

output "careerpost_wif_provider" {
  description = "WIF_PROVIDER for careerpost repo GitHub secrets"
  value       = module.careerpost_identity.wif_provider
}

output "careerpost_gcp_sa_email" {
  description = "GCP_SA_EMAIL for careerpost repo GitHub secrets"
  value       = module.careerpost_identity.ci_cd_sa_email
}

output "careerpost_hosting_url" {
  description = "Firebase Hosting URL"
  value       = module.careerpost_hosting.site_url
}

output "careerpost_custom_domain" {
  description = "Custom domain for careerpost"
  value       = google_firebase_hosting_custom_domain.careerpost.custom_domain
}

output "careerpost_required_dns" {
  description = "DNS records required at the registrar to verify and serve the custom domain"
  value       = google_firebase_hosting_custom_domain.careerpost.required_dns_updates
}

output "careerpost_cloud_run_url" {
  description = "Cloud Run URL for the careerpost PHP backend"
  value       = google_cloud_run_v2_service.careerpost.uri
}

output "photobank_wif_provider" {
  description = "WIF_PROVIDER for photobank repo GitHub secrets"
  value       = module.photobank_identity.wif_provider
}

output "photobank_gcp_sa_email" {
  description = "GCP_SA_EMAIL for photobank repo GitHub secrets"
  value       = module.photobank_identity.ci_cd_sa_email
}

output "photobank_hosting_url" {
  description = "Firebase Hosting URL"
  value       = module.photobank_hosting.site_url
}

output "photobank_custom_domain" {
  description = "Custom domain for photobank"
  value       = google_firebase_hosting_custom_domain.photobank.custom_domain
}

output "photobank_required_dns" {
  description = "DNS records required at the registrar to verify and serve the custom domain"
  value       = google_firebase_hosting_custom_domain.photobank.required_dns_updates
}

output "photobank_cloud_run_url" {
  description = "Cloud Run URL for the photobank PHP backend"
  value       = google_cloud_run_v2_service.photobank.uri
}

output "photobank_uploads_bucket" {
  description = "Bucket mounted at /var/www/html/uploads"
  value       = google_storage_bucket.photobank_uploads.name
}

# ── Parley Outputs ──────────────────────────────────────────
output "parley_wif_provider" {
  description = "WIF_PROVIDER for parley repo GitHub secrets"
  value       = module.parley.wif_provider
}

output "parley_gcp_sa_email" {
  description = "GCP_SA_EMAIL for parley repo GitHub secrets"
  value       = module.parley.ci_cd_sa_email
}

output "parley_cloud_run_url" {
  description = "Cloud Run URL for parley"
  value       = module.parley.service_url
}

output "parley_uploads_bucket" {
  description = "GCS bucket holding parley media uploads"
  value       = module.parley.uploads_bucket
}

# ── Outrun Outputs ──────────────────────────────────────────
output "outrun_wif_provider" {
  description = "WIF_PROVIDER for outrun repo GitHub secrets"
  value       = module.outrun_identity.wif_provider
}

output "outrun_gcp_sa_email" {
  description = "GCP_SA_EMAIL for outrun repo GitHub secrets"
  value       = module.outrun_identity.ci_cd_sa_email
}

output "outrun_hosting_url" {
  description = "Firebase Hosting URL for outrun"
  value       = module.outrun_hosting.site_url
}

output "parley_hosting_url" {
  description = "Firebase Hosting URL"
  value       = module.parley_hosting.site_url
}

output "parley_custom_domain" {
  description = "Custom domain for parley"
  value       = google_firebase_hosting_custom_domain.parley.custom_domain
}

output "parley_required_dns" {
  description = "DNS records required at the registrar to verify and serve the custom domain"
  value       = google_firebase_hosting_custom_domain.parley.required_dns_updates
}

# ── Legal Outputs ───────────────────────────────────────────
output "legal_wif_provider" {
  description = "WIF_PROVIDER for legal repo GitHub secrets"
  value       = module.legal.wif_provider
}

output "legal_gcp_sa_email" {
  description = "GCP_SA_EMAIL for legal repo GitHub secrets"
  value       = module.legal.ci_cd_sa_email
}

output "legal_cloud_run_url" {
  description = "Cloud Run URL for legal"
  value       = module.legal.service_url
}

output "legal_uploads_bucket" {
  description = "GCS bucket holding legal media uploads"
  value       = module.legal.uploads_bucket
}

output "legal_hosting_url" {
  description = "Firebase Hosting URL"
  value       = module.legal_hosting.site_url
}

output "legal_custom_domain" {
  description = "Custom domain for legal"
  value       = google_firebase_hosting_custom_domain.legal.custom_domain
}

output "legal_required_dns" {
  description = "DNS records required at the registrar to verify and serve the custom domain"
  value       = google_firebase_hosting_custom_domain.legal.required_dns_updates
}

# ─────────────────────────────────────────────────────────────
# cms Outputs
# ─────────────────────────────────────────────────────────────
output "cms_wif_provider" {
  description = "WIF_PROVIDER for the cms repo GitHub secrets"
  value       = module.cms_identity.wif_provider
}

output "cms_gcp_sa_email" {
  description = "GCP_SA_EMAIL for the cms repo GitHub secrets"
  value       = module.cms_identity.ci_cd_sa_email
}

output "cms_cloud_run_url" {
  description = "Cloud Run service URL for cms"
  value       = google_cloud_run_v2_service.cms.uri
}

output "cms_uploads_bucket" {
  description = "GCS bucket holding cms media uploads"
  value       = google_storage_bucket.cms_uploads.name
}

output "cms_hosting_url" {
  description = "Firebase Hosting default URL for cms"
  value       = "https://${google_firebase_hosting_site.cms.site_id}.web.app"
}

output "cms_custom_domain" {
  description = "Custom domain for cms"
  value       = google_firebase_hosting_custom_domain.cms.custom_domain
}

output "cms_required_dns" {
  description = "DNS records required at the registrar to verify and serve the custom domain"
  value       = google_firebase_hosting_custom_domain.cms.required_dns_updates
}
