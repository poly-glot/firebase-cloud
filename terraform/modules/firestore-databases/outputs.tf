output "database_name" {
  description = "Firestore database name"
  value       = google_firestore_database.app.name
}
