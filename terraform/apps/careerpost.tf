# ─────────────────────────────────────────────────────────────
# careerpost — 2004-era PHP job portal on Cloud Run + OCI HeatWave MySQL
# ─────────────────────────────────────────────────────────────
# Firebase Hosting owns careerpost.junaid.guru: it serves /images and
# /stylesheet.css from its CDN and rewrites every other path to the
# Cloud Run service (firebase.json in the app repo). The PHP backend
# talks to the shared OCI HeatWave MySQL over the public NLB with TLS.
# The app repo's CI runs install/install.php against that database on
# every deploy; it is a no-op once the schema exists.
# ─────────────────────────────────────────────────────────────

# ── Identity: SA + WIF Provider ─────────────────────────────
module "careerpost_identity" {
  source = "../modules/app-identity"

  project_id    = var.project_id
  app_name      = "careerpost"
  github_org    = var.github_org
  github_repo   = "careerpost"
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
module "careerpost_hosting" {
  source = "../modules/hosting"

  project_id = var.project_id
  site_id    = "careerpost"
}

resource "google_firebase_hosting_custom_domain" "careerpost" {
  provider      = google-beta
  project       = var.project_id
  site_id       = module.careerpost_hosting.site_id
  custom_domain = "careerpost.junaid.guru"

  wait_dns_verification = false
}

# ── Per-app DB + secret shells ──────────────────────────────
module "careerpost_db" {
  source = "../modules/app-with-mysql"

  project_id       = var.project_id
  app_name         = "careerpost"
  database_name    = "careerpost"
  runtime_sa_email = module.careerpost_identity.runtime_sa_email
}

# CI reads these to run install/install.php from the GitHub Actions runner.
locals {
  careerpost_ci_db_secrets = [
    "db-host",
    "careerpost-db-user",
    "careerpost-db-pass",
    "careerpost-db-name",
  ]
}

resource "google_secret_manager_secret_iam_member" "careerpost_ci_db_read" {
  for_each  = toset(local.careerpost_ci_db_secrets)
  project   = var.project_id
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.careerpost_identity.ci_cd_sa_email}"

  depends_on = [module.careerpost_db]
}

# ── Cloud Run (inlined to wire Secret Manager refs) ─────────
resource "google_cloud_run_v2_service" "careerpost" {
  provider = google-beta
  project  = var.project_id
  name     = "careerpost"
  location = var.region

  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = module.careerpost_identity.runtime_sa_email

    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }

    containers {
      # Bootstrap placeholder; the careerpost repo's CI pushes the real
      # image and swaps it in with `gcloud run deploy --image=...`.
      image = "gcr.io/cloudrun/hello"

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
        cpu_idle          = true
        startup_cpu_boost = true
      }

      env {
        name  = "DB_SSL"
        value = "1"
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
            secret  = "careerpost-db-user"
            version = "latest"
          }
        }
      }

      env {
        name = "DB_PASS"
        value_source {
          secret_key_ref {
            secret  = "careerpost-db-pass"
            version = "latest"
          }
        }
      }

      env {
        name = "DB_NAME"
        value_source {
          secret_key_ref {
            secret  = "careerpost-db-name"
            version = "latest"
          }
        }
      }

      # Static file served by Apache: proves the container is up without
      # touching the database.
      startup_probe {
        http_get {
          path = "/stylesheet.css"
        }
        initial_delay_seconds = 2
        period_seconds        = 5
        failure_threshold     = 6
        timeout_seconds       = 3
      }

      liveness_probe {
        http_get {
          path = "/stylesheet.css"
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
    module.careerpost_db,
  ]
}

resource "google_cloud_run_v2_service_iam_member" "careerpost_public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.careerpost.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
