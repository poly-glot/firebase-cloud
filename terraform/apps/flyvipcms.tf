# ─────────────────────────────────────────────────────────────
# flyvipcms — CodeIgniter 4 membership CMS on Cloud Run + OCI HeatWave MySQL
# ─────────────────────────────────────────────────────────────
# Firebase Hosting fronts flyvipcms.junaid.guru and rewrites every path to
# the Cloud Run service. Hosting forwards only the __session cookie, so the
# app names its DB-backed session cookie __session. The container runs
# `php spark migrate --all` on boot against the shared OCI MySQL over TLS.
# ─────────────────────────────────────────────────────────────

locals {
  flyvipcms_ci_db_secrets = [
    "db-host",
    "flyvipcms-db-user",
    "flyvipcms-db-pass",
    "flyvipcms-db-name",
  ]
}

module "flyvipcms_identity" {
  source = "../modules/app-identity"

  project_id    = var.project_id
  app_name      = "flyvipcms"
  github_org    = var.github_org
  github_repo   = "flyvipcms"
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

module "flyvipcms_db" {
  source = "../modules/app-with-mysql"

  project_id       = var.project_id
  app_name         = "flyvipcms"
  database_name    = "flyvipcms"
  runtime_sa_email = module.flyvipcms_identity.runtime_sa_email
}

resource "google_secret_manager_secret_iam_member" "flyvipcms_ci_db_read" {
  for_each  = toset(local.flyvipcms_ci_db_secrets)
  project   = var.project_id
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.flyvipcms_identity.ci_cd_sa_email}"

  depends_on = [module.flyvipcms_db]
}

resource "google_cloud_run_v2_service" "flyvipcms" {
  provider = google-beta
  project  = var.project_id
  name     = "flyvipcms"
  location = var.region

  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"

  template {
    service_account                  = module.flyvipcms_identity.runtime_sa_email
    max_instance_request_concurrency = 20

    scaling {
      min_instance_count = 0
      max_instance_count = 2
    }

    containers {
      image = "gcr.io/cloudrun/hello"

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
        cpu_idle          = true
        startup_cpu_boost = true
      }

      startup_probe {
        http_get { path = "/health" }
        period_seconds    = 5
        timeout_seconds   = 3
        failure_threshold = 20
      }

      env {
        name  = "CI_ENVIRONMENT"
        value = "production"
      }

      env {
        name  = "APP_FULL_BASE_URL"
        value = "https://flyvipcms.junaid.guru/"
      }

      env {
        name  = "COOKIE_SECURE"
        value = "true"
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
            secret  = "flyvipcms-db-user"
            version = "latest"
          }
        }
      }

      env {
        name = "DB_PASS"
        value_source {
          secret_key_ref {
            secret  = "flyvipcms-db-pass"
            version = "latest"
          }
        }
      }

      env {
        name = "DB_NAME"
        value_source {
          secret_key_ref {
            secret  = "flyvipcms-db-name"
            version = "latest"
          }
        }
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

  depends_on = [module.flyvipcms_db]
}

resource "google_cloud_run_v2_service_iam_member" "flyvipcms_public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.flyvipcms.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_firebase_hosting_site" "flyvipcms" {
  provider = google-beta
  project  = var.project_id
  site_id  = "flyvipcms-junaid-guru"
}

resource "google_firebase_hosting_version" "flyvipcms" {
  provider = google-beta
  site_id  = google_firebase_hosting_site.flyvipcms.site_id

  config {
    rewrites {
      glob = "**"
      run {
        service_id = google_cloud_run_v2_service.flyvipcms.name
        region     = var.region
      }
    }
  }

  depends_on = [google_cloud_run_v2_service.flyvipcms]
}

resource "google_firebase_hosting_release" "flyvipcms" {
  provider     = google-beta
  site_id      = google_firebase_hosting_site.flyvipcms.site_id
  version_name = google_firebase_hosting_version.flyvipcms.name
  message      = "Route all traffic to Cloud Run"
}

resource "google_firebase_hosting_custom_domain" "flyvipcms" {
  provider      = google-beta
  project       = var.project_id
  site_id       = google_firebase_hosting_site.flyvipcms.site_id
  custom_domain = "flyvipcms.junaid.guru"

  wait_dns_verification = false
}
