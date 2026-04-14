# ─────────────────────────────────────────────────────────────
# MySQL Keep-Alive — OCI HeatWave Inactivity Prevention
# ─────────────────────────────────────────────────────────────
# Cloud Run Job + Cloud Scheduler to ping OCI HeatWave MySQL
# daily, preventing Oracle from marking it INACTIVE after 7
# days of no connections.
#
# Image: docker/mysql-keepalive/Dockerfile (built by this repo's CI)
# Schedule: 06:00 UTC daily
# ─────────────────────────────────────────────────────────────

# ── Service Account ──────────────────────────────────────────

resource "google_service_account" "mysql_keepalive" {
  project      = var.project_id
  account_id   = "mysql-keepalive"
  display_name = "MySQL Keep-Alive Job Runner"
}

resource "google_project_iam_member" "mysql_keepalive_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.mysql_keepalive.email}"
}

resource "google_project_iam_member" "mysql_keepalive_secrets" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.mysql_keepalive.email}"
}

# ── Secrets (shells — values populated out-of-band via gcloud) ──
# Import blocks for these live in terraform/imports.tf (root module).

resource "google_secret_manager_secret" "db_host" {
  project   = var.project_id
  secret_id = "db-host"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "db_user" {
  project   = var.project_id
  secret_id = "db-user"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "db_pass" {
  project   = var.project_id
  secret_id = "db-pass"
  replication {
    auto {}
  }
}

# ── Cloud Run Job ─────────────────────────────────────────────

resource "google_cloud_run_v2_job" "mysql_keepalive" {
  provider = google-beta
  project  = var.project_id
  name     = "mysql-keepalive"
  location = var.region

  template {
    template {
      service_account = google_service_account.mysql_keepalive.email
      max_retries     = 2

      containers {
        image = "${var.region}-docker.pkg.dev/${var.project_id}/firebase-cloud/mysql-keepalive:latest"

        env {
          name = "DB_HOST"
          value_source {
            secret_key_ref {
              secret  = google_secret_manager_secret.db_host.secret_id
              version = "latest"
            }
          }
        }

        env {
          name = "DB_USER"
          value_source {
            secret_key_ref {
              secret  = google_secret_manager_secret.db_user.secret_id
              version = "latest"
            }
          }
        }

        env {
          name = "DB_PASS"
          value_source {
            secret_key_ref {
              secret  = google_secret_manager_secret.db_pass.secret_id
              version = "latest"
            }
          }
        }

        resources {
          limits = {
            cpu    = "1"
            memory = "512Mi"
          }
        }
      }
    }
  }

  depends_on = [
    google_project_iam_member.mysql_keepalive_secrets,
    google_project_iam_member.mysql_keepalive_logging,
  ]
}

# ── Cloud Scheduler ───────────────────────────────────────────
# Invokes the Cloud Run Job via the Jobs execution API.
# Audience must be https://run.googleapis.com/ (not the job URL).

resource "google_service_account" "mysql_keepalive_scheduler" {
  project      = var.project_id
  account_id   = "mysql-keepalive-scheduler"
  display_name = "MySQL Keep-Alive Scheduler Invoker"
}

resource "google_cloud_run_v2_job_iam_member" "scheduler_invoker" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_job.mysql_keepalive.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.mysql_keepalive_scheduler.email}"
}

resource "google_cloud_scheduler_job" "mysql_keepalive" {
  project     = var.project_id
  region      = var.region
  name        = "mysql-keepalive-daily"
  description = "Daily OCI HeatWave MySQL ping to prevent INACTIVE state"
  schedule    = "0 6 * * *"
  time_zone   = "UTC"

  http_target {
    uri         = "https://run.googleapis.com/v2/projects/${var.project_id}/locations/${var.region}/jobs/mysql-keepalive:run"
    http_method = "POST"
    body        = base64encode("{}")

    oauth_token {
      service_account_email = google_service_account.mysql_keepalive_scheduler.email
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
    }
  }

  retry_config {
    retry_count          = 3
    min_backoff_duration = "5s"
    max_backoff_duration = "300s"
    max_doublings        = 3
  }

  depends_on = [google_cloud_run_v2_job_iam_member.scheduler_invoker]
}