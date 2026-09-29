# ─────────────────────────────────────────────────────────────
# cms — CakePHP 5 CMS on Cloud Run + OCI HeatWave MySQL + GCS uploads
# ─────────────────────────────────────────────────────────────
# Firebase Hosting fronts cms.junaid.guru and rewrites every path to
# the Cloud Run service. The uploads bucket is mounted into the
# container at /app/storage/uploads via GCS FUSE; a public/ prefix
# on the bucket is world-readable so BlockExpander can emit direct
# storage.googleapis.com URLs and skip the PHP stream.
# ─────────────────────────────────────────────────────────────

locals {
  cms_uploads_bucket = "${var.project_id}-cms-uploads"

  cms_ci_db_secrets = [
    "db-host",
    "cms-db-user",
    "cms-db-pass",
    "cms-db-name",
  ]
}

module "cms_identity" {
  source = "../modules/app-identity"

  project_id    = var.project_id
  app_name      = "cms"
  github_org    = var.github_org
  github_repo   = "cms"
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

module "cms_db" {
  source = "../modules/app-with-mysql"

  project_id       = var.project_id
  app_name         = "cms"
  database_name    = "cms"
  runtime_sa_email = module.cms_identity.runtime_sa_email
}

resource "google_secret_manager_secret_iam_member" "cms_ci_db_read" {
  for_each  = toset(local.cms_ci_db_secrets)
  project   = var.project_id
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.cms_identity.ci_cd_sa_email}"

  depends_on = [module.cms_db]
}

resource "google_storage_bucket" "cms_uploads" {
  project                     = var.project_id
  name                        = local.cms_uploads_bucket
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = false

  cors {
    origin          = ["https://cms.junaid.guru"]
    method          = ["GET", "HEAD"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}

resource "google_storage_bucket_iam_member" "cms_uploads_runtime_admin" {
  bucket = google_storage_bucket.cms_uploads.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.cms_identity.runtime_sa_email}"
}

resource "google_storage_bucket_iam_member" "cms_uploads_public_prefix" {
  bucket = google_storage_bucket.cms_uploads.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"

  condition {
    title      = "public-prefix-only"
    expression = "resource.name.startsWith(\"projects/_/buckets/${google_storage_bucket.cms_uploads.name}/objects/public/\")"
  }
}

resource "google_cloud_run_v2_service" "cms" {
  provider = google-beta
  project  = var.project_id
  name     = "cms"
  location = var.region

  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"

  template {
    service_account                  = module.cms_identity.runtime_sa_email
    max_instance_request_concurrency = 20

    scaling {
      min_instance_count = 0
      max_instance_count = 2
    }

    volumes {
      name = "uploads"
      gcs {
        bucket    = google_storage_bucket.cms_uploads.name
        read_only = false
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
        mount_path = "/app/storage/uploads"
      }

      startup_probe {
        http_get { path = "/health" }
        period_seconds    = 5
        timeout_seconds   = 3
        failure_threshold = 20
      }

      env {
        name  = "APP_ENV"
        value = "production"
      }

      env {
        name  = "DEBUG"
        value = "false"
      }

      env {
        name  = "APP_FULL_BASE_URL"
        value = "https://cms.junaid.guru"
      }

      env {
        name  = "UPLOADS_PATH"
        value = "/app/storage/uploads"
      }

      env {
        name  = "MEDIA_PUBLIC_BASE"
        value = "https://storage.googleapis.com/${google_storage_bucket.cms_uploads.name}"
      }

      env {
        name  = "SESSION_DEFAULTS"
        value = "database"
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
            secret  = "cms-db-user"
            version = "latest"
          }
        }
      }

      env {
        name = "DB_PASS"
        value_source {
          secret_key_ref {
            secret  = "cms-db-pass"
            version = "latest"
          }
        }
      }

      env {
        name = "DB_NAME"
        value_source {
          secret_key_ref {
            secret  = "cms-db-name"
            version = "latest"
          }
        }
      }

      env {
        name = "SECURITY_SALT"
        value_source {
          secret_key_ref {
            secret  = "cms-security-salt"
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

  depends_on = [
    module.cms_db,
    google_secret_manager_secret.cms_security_salt,
  ]
}

resource "google_cloud_run_v2_service_iam_member" "cms_public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.cms.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_secret_manager_secret" "cms_security_salt" {
  project   = var.project_id
  secret_id = "cms-security-salt"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_iam_member" "cms_security_salt_runtime" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.cms_security_salt.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.cms_identity.runtime_sa_email}"
}

resource "google_firebase_hosting_site" "cms" {
  provider = google-beta
  project  = var.project_id
  site_id  = "cms-junaid-guru"
}

resource "google_firebase_hosting_version" "cms" {
  provider = google-beta
  site_id  = google_firebase_hosting_site.cms.site_id

  config {
    rewrites {
      glob = "**"
      run {
        service_id = google_cloud_run_v2_service.cms.name
        region     = var.region
      }
    }
  }

  depends_on = [google_cloud_run_v2_service.cms]
}

resource "google_firebase_hosting_release" "cms" {
  provider     = google-beta
  site_id      = google_firebase_hosting_site.cms.site_id
  version_name = google_firebase_hosting_version.cms.name
  message      = "Route all traffic to Cloud Run"
}

resource "google_firebase_hosting_custom_domain" "cms" {
  provider      = google-beta
  project       = var.project_id
  site_id       = google_firebase_hosting_site.cms.site_id
  custom_domain = "cms.junaid.guru"

  wait_dns_verification = false
}
