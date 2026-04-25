# ─────────────────────────────────────────────────────────────
# shehryar — Static site + PHP chatapp on Cloud Run + OCI HeatWave MySQL
# ─────────────────────────────────────────────────────────────
# Firebase Hosting serves the static site. /chatapp/** is rewritten
# to a Cloud Run service (shehryar-api) running the PHP backend.
# The backend talks to OCI HeatWave MySQL (free tier) over the public
# internet; the daily keep-alive (mysql-keepalive.tf) prevents Oracle
# from marking the instance INACTIVE after 7 days of silence.
# ─────────────────────────────────────────────────────────────

# ── Identity: SA + WIF Provider ─────────────────────────────
module "shehryar_identity" {
  source = "../modules/app-identity"

  project_id    = var.project_id
  app_name      = "shehryar"
  github_org    = var.github_org
  github_repo   = "shehryar"
  wif_pool_id   = var.wif_pool_id
  wif_pool_name = var.wif_pool_name

  ci_cd_roles = [
    "roles/firebasehosting.admin",
    "roles/firebase.admin",
    "roles/run.admin",
    "roles/artifactregistry.writer",
    "roles/iam.serviceAccountUser",
    "roles/serviceusage.serviceUsageConsumer",
  ]

  runtime_roles = [
    "roles/secretmanager.secretAccessor",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/cloudtrace.agent",
  ]
}

# ── Firebase Hosting ────────────────────────────────────────
module "shehryar_hosting" {
  source = "../modules/hosting"

  project_id = var.project_id
  site_id    = "shehryar"
}

resource "google_firebase_hosting_custom_domain" "shehryar" {
  provider      = google-beta
  project       = var.project_id
  site_id       = module.shehryar_hosting.site_id
  custom_domain = "shehryar.junaid.guru"

  wait_dns_verification = false
}

# ── Per-app DB + secret shells ──────────────────────────────
# Owned by the app-with-mysql module: creates shehryar-db-{user,pass,name}
# shells, grants runtime SA reader on them and on db-host, and emits an
# app_entry consumed by mysql-catalog.tf. Versions are populated by
# personal-cloud terraform on its next apply.
module "shehryar_db" {
  source = "../modules/app-with-mysql"

  project_id       = var.project_id
  app_name         = "shehryar"
  database_name    = "rn_chatapp"
  runtime_sa_email = module.shehryar_identity.runtime_sa_email
}

# ── Cloud Run (inlined to wire Secret Manager refs) ─────────
resource "google_cloud_run_v2_service" "shehryar_api" {
  provider = google-beta
  project  = var.project_id
  name     = "shehryar-api"
  location = var.region

  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = module.shehryar_identity.runtime_sa_email

    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }

    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/firebase-cloud/shehryar-api:latest"

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
        cpu_idle          = true
        startup_cpu_boost = true
      }

      env {
        name  = "APP_ENV"
        value = "production"
      }

      env {
        name = "DB_HOST"
        value_source {
          secret_key_ref {
            secret  = "db-host"
            version = "latest"
          }
        }
      }

      env {
        name = "DB_USER"
        value_source {
          secret_key_ref {
            secret  = "shehryar-db-user"
            version = "latest"
          }
        }
      }

      env {
        name = "DB_PASS"
        value_source {
          secret_key_ref {
            secret  = "shehryar-db-pass"
            version = "latest"
          }
        }
      }

      env {
        name = "DB_NAME"
        value_source {
          secret_key_ref {
            secret  = "shehryar-db-name"
            version = "latest"
          }
        }
      }

      startup_probe {
        http_get {
          path = "/chatapp/health.php"
        }
        initial_delay_seconds = 5
        period_seconds        = 10
        failure_threshold     = 3
        timeout_seconds       = 3
      }

      liveness_probe {
        http_get {
          path = "/"
        }
        period_seconds    = 30
        failure_threshold = 3
        timeout_seconds   = 3
      }
    }

    timeout               = "300s"
    execution_environment = "EXECUTION_ENVIRONMENT_GEN2"
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
      traffic,
    ]
  }

  depends_on = [
    module.shehryar_db,
  ]
}

resource "google_cloud_run_v2_service_iam_member" "shehryar_api_public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.shehryar_api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
