# ─────────────────────────────────────────────────────────────
# photobank — 2004-era PHP photo gallery on Cloud Run + OCI HeatWave MySQL
# ─────────────────────────────────────────────────────────────
# Firebase Hosting owns photobank.junaid.guru: it serves /images and
# /stylesheet.css from its CDN and rewrites every other path to the
# Cloud Run service. Member uploads and the demo photographs live in a
# Cloud Storage bucket mounted into the container at /var/www/html/uploads
# so the 2004-style PHP keeps writing plain files while Cloud Run stays
# stateless. The app repo's CI runs install/install.php on every deploy;
# it is a no-op once the schema exists.
# ─────────────────────────────────────────────────────────────

module "photobank_identity" {
  source = "../modules/app-identity"

  project_id    = var.project_id
  app_name      = "photobank"
  github_org    = var.github_org
  github_repo   = "photobank"
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

module "photobank_hosting" {
  source = "../modules/hosting"

  project_id = var.project_id
  site_id    = "photobank"
}

resource "google_firebase_hosting_custom_domain" "photobank" {
  provider      = google-beta
  project       = var.project_id
  site_id       = module.photobank_hosting.site_id
  custom_domain = "photobank.junaid.guru"

  wait_dns_verification = false
}

module "photobank_db" {
  source = "../modules/app-with-mysql"

  project_id       = var.project_id
  app_name         = "photobank"
  database_name    = "photobank"
  runtime_sa_email = module.photobank_identity.runtime_sa_email
}

locals {
  photobank_ci_db_secrets = [
    "db-host",
    "photobank-db-user",
    "photobank-db-pass",
    "photobank-db-name",
  ]
}

resource "google_secret_manager_secret_iam_member" "photobank_ci_db_read" {
  for_each  = toset(local.photobank_ci_db_secrets)
  project   = var.project_id
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.photobank_identity.ci_cd_sa_email}"

  depends_on = [module.photobank_db]
}

# ── Uploads bucket, mounted into the container ──────────────
resource "google_storage_bucket" "photobank_uploads" {
  project                     = var.project_id
  name                        = "${var.project_id}-photobank-uploads"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}

resource "google_storage_bucket_iam_member" "photobank_uploads_object_admin" {
  bucket = google_storage_bucket.photobank_uploads.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.photobank_identity.runtime_sa_email}"
}

resource "google_storage_bucket_iam_member" "photobank_uploads_ci_admin" {
  bucket = google_storage_bucket.photobank_uploads.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.photobank_identity.ci_cd_sa_email}"
}

resource "google_cloud_run_v2_service" "photobank" {
  provider = google-beta
  project  = var.project_id
  name     = "photobank"
  location = var.region

  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = module.photobank_identity.runtime_sa_email

    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }

    volumes {
      name = "uploads"
      gcs {
        bucket        = google_storage_bucket.photobank_uploads.name
        read_only     = false
        mount_options = ["uid=33", "gid=33", "file-mode=0664", "dir-mode=0775", "implicit-dirs"]
      }
    }

    containers {
      image = "gcr.io/cloudrun/hello"

      resources {
        limits = {
          cpu    = "1"
          memory = "1Gi"
        }
        cpu_idle          = true
        startup_cpu_boost = true
      }

      volume_mounts {
        name       = "uploads"
        mount_path = "/var/www/html/uploads"
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
            secret  = "photobank-db-user"
            version = "latest"
          }
        }
      }

      env {
        name = "DB_PASS"
        value_source {
          secret_key_ref {
            secret  = "photobank-db-pass"
            version = "latest"
          }
        }
      }

      env {
        name = "DB_NAME"
        value_source {
          secret_key_ref {
            secret  = "photobank-db-name"
            version = "latest"
          }
        }
      }

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
    module.photobank_db,
  ]
}

resource "google_cloud_run_v2_service_iam_member" "photobank_public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.photobank.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
