output "site_url" {
  description = "Firebase Hosting site URL"
  value       = "https://${var.site_id}.web.app"
}

output "default_url" {
  description = "Firebase Hosting default URL"
  value       = "https://${var.site_id}.firebaseapp.com"
}

output "site_id" {
  description = "Firebase Hosting site ID"
  value       = google_firebase_hosting_site.default.site_id
}
