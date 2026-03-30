# ─────────────────────────────────────────────────────────────
# Cloud Scheduler Jobs (per-app)
# ─────────────────────────────────────────────────────────────

resource "google_cloud_scheduler_job" "jobs" {
  for_each = var.jobs

  project     = var.project_id
  region      = var.region
  name        = each.key
  schedule    = each.value.schedule
  description = each.value.description
  time_zone   = "UTC"

  http_target {
    uri         = each.value.uri
    http_method = each.value.http_method
    body        = each.value.body != "" ? base64encode(each.value.body) : null

    oidc_token {
      service_account_email = var.service_account_email
      audience              = each.value.uri
    }
  }

  retry_config {
    retry_count          = 3
    min_backoff_duration = "5s"
    max_backoff_duration = "300s"
    max_doublings        = 3
  }
}