# ─────────────────────────────────────────────────────────────
# Per-App Named Firestore Database
# ─────────────────────────────────────────────────────────────
# Each app gets its own named database for full isolation:
#   - Separate security rules
#   - Separate indexes
#   - No collection collisions
#   - Independent backup/restore
# ─────────────────────────────────────────────────────────────

resource "google_firestore_database" "app" {
  provider    = google-beta
  project     = var.project_id
  name        = var.database_name
  location_id = var.region == "us-central1" ? "nam5" : var.region
  type        = "FIRESTORE_NATIVE"
}
