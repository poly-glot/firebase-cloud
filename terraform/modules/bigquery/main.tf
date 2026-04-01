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

# ── Executions table (streaming insert target for webhooks) ──
resource "google_bigquery_table" "executions" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.app.dataset_id
  table_id   = "executions"

  deletion_protection = false

  time_partitioning {
    type  = "DAY"
    field = "execution_timestamp"
  }

  schema = jsonencode([
    { name = "id",                  type = "STRING",    mode = "REQUIRED" },
    { name = "endpoint_id",         type = "STRING",    mode = "REQUIRED" },
    { name = "user_id",             type = "STRING",    mode = "REQUIRED" },
    { name = "method",              type = "STRING",    mode = "NULLABLE" },
    { name = "url",                 type = "STRING",    mode = "NULLABLE" },
    { name = "status",              type = "STRING",    mode = "NULLABLE" },
    { name = "response_status",     type = "INT64",     mode = "NULLABLE" },
    { name = "duration_ms",         type = "FLOAT64",   mode = "NULLABLE" },
    { name = "ip",                  type = "STRING",    mode = "NULLABLE" },
    { name = "execution_timestamp", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "request_body",        type = "STRING",    mode = "NULLABLE" },
    { name = "response_body",       type = "STRING",    mode = "NULLABLE" },
    { name = "request_headers",     type = "STRING",    mode = "NULLABLE" },
    { name = "query_params",        type = "STRING",    mode = "NULLABLE" },
  ])

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

resource "google_project_iam_member" "bq_data_editor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${var.runtime_sa_email}"
}

resource "google_project_iam_member" "vertex_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${var.runtime_sa_email}"
}
