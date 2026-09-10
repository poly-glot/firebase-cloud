terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.0"
    }
  }
}

locals {
  db_secret_user = "${var.app_name}-db-user"
  db_secret_pass = "${var.app_name}-db-pass"
  db_secret_name = "${var.app_name}-db-name"

  ci_db_secrets = [
    "db-host",
    local.db_secret_user,
    local.db_secret_pass,
    local.db_secret_name,
  ]

  runtime_roles = concat([
    "roles/secretmanager.secretAccessor",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/cloudtrace.agent",
  ], var.extra_runtime_roles)
}

module "identity" {
  source = "../app-identity"

  project_id    = var.project_id
  app_name      = var.app_name
  github_org    = var.github_org
  github_repo   = var.github_repo
  wif_pool_id   = var.wif_pool_id
  wif_pool_name = var.wif_pool_name

  ci_cd_roles = [
    "roles/run.admin",
    "roles/artifactregistry.writer",
    "roles/iam.serviceAccountUser",
    "roles/serviceusage.serviceUsageConsumer",
  ]

  runtime_roles = local.runtime_roles
}

module "db" {
  source = "../app-with-mysql"

  project_id       = var.project_id
  app_name         = var.app_name
  database_name    = var.database_name
  runtime_sa_email = module.identity.runtime_sa_email
}

resource "google_secret_manager_secret_iam_member" "ci_db_read" {
  for_each  = toset(local.ci_db_secrets)
  project   = var.project_id
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.identity.ci_cd_sa_email}"

  depends_on = [module.db]
}

resource "google_storage_bucket" "uploads" {
  project                     = var.project_id
  name                        = "${var.project_id}-${var.app_name}-uploads"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}

resource "google_storage_bucket_iam_member" "uploads_object_admin" {
  bucket = google_storage_bucket.uploads.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.identity.runtime_sa_email}"
}

resource "google_storage_bucket_iam_member" "uploads_public_read" {
  count  = var.public_uploads ? 1 : 0
  bucket = google_storage_bucket.uploads.name
  member = "allUsers"
  role   = "roles/storage.objectViewer"
}

resource "google_cloud_run_v2_service" "this" {
  provider = google-beta
  project  = var.project_id
  name     = var.app_name
  location = var.region

  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"

  template {
    service_account                  = module.identity.runtime_sa_email
    max_instance_request_concurrency = var.concurrency

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    containers {
      image = var.image

      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
        cpu_idle          = true
        startup_cpu_boost = true
      }

      env {
        name  = "DB_SSL"
        value = "1"
      }

      env {
        name  = "GCS_UPLOADS_BUCKET"
        value = google_storage_bucket.uploads.name
      }

      dynamic "env" {
        for_each = var.extra_env
        content {
          name  = env.key
          value = env.value
        }
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
            secret  = local.db_secret_user
            version = "latest"
          }
        }
      }

      env {
        name = "DB_PASS"
        value_source {
          secret_key_ref {
            secret  = local.db_secret_pass
            version = "latest"
          }
        }
      }

      env {
        name = "DB_NAME"
        value_source {
          secret_key_ref {
            secret  = local.db_secret_name
            version = "latest"
          }
        }
      }

      startup_probe {
        http_get {
          path = "/"
        }
        initial_delay_seconds = 0
        period_seconds        = 2
        failure_threshold     = 15
        timeout_seconds       = 2
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

  depends_on = [module.db]
}

resource "google_cloud_run_v2_service_iam_member" "public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.this.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_scheduler_job" "cron" {
  project          = var.project_id
  region           = var.region
  name             = "${var.app_name}-cron"
  description      = "WordPress cron for ${var.app_name}"
  schedule         = var.cron_schedule
  time_zone        = "UTC"
  attempt_deadline = "180s"

  http_target {
    uri         = "${google_cloud_run_v2_service.this.uri}/wp-cron.php?doing_wp_cron"
    http_method = "GET"
  }
}
