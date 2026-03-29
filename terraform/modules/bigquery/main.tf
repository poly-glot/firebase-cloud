# ─────────────────────────────────────────────────────────────
# BigQuery Dataset + Vertex AI (per-app)
# ─────────────────────────────────────────────────────────────

resource "google_bigquery_dataset" "app" {
  project       = var.project_id
  dataset_id    = var.dataset_id
  friendly_name = "${var.app_name} Analytics"
  location      = var.region

  default_table_expiration_ms = 15552000000 # 180 days

  labels = {
    env     = "production"
    product = var.app_name
  }
}

# ── IAM: Runtime SA needs BigQuery + Vertex AI access ──────
resource "google_project_iam_member" "bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${var.runtime_sa_email}"
}

resource "google_project_iam_member" "bq_data_viewer" {
  project = var.project_id
  role    = "roles/bigquery.dataViewer"
  member  = "serviceAccount:${var.runtime_sa_email}"
}

resource "google_project_iam_member" "vertex_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${var.runtime_sa_email}"
}
