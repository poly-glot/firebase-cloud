output "wif_provider" {
  description = "WIF_PROVIDER GitHub secret for the app repo"
  value       = module.identity.wif_provider
}

output "ci_cd_sa_email" {
  description = "GCP_SA_EMAIL GitHub secret for the app repo"
  value       = module.identity.ci_cd_sa_email
}

output "runtime_sa_email" {
  description = "Runtime service account email"
  value       = module.identity.runtime_sa_email
}

output "service_url" {
  description = "Cloud Run service URL"
  value       = google_cloud_run_v2_service.this.uri
}

output "uploads_bucket" {
  description = "GCS bucket holding media uploads"
  value       = google_storage_bucket.uploads.name
}

output "db_app_entry" {
  description = "Entry to add to apps/mysql-catalog.tf local.mysql_apps so personal-cloud provisions the database"
  value       = module.db.app_entry
}
