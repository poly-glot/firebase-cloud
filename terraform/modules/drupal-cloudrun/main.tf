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

  ci_db_secrets = ["db-host", local.db_secret_user, local.db_secret_pass, local.db_secret_name]

  app_secret_kinds = ["hash-salt", "admin-pass", "canvas-client-secret", "oauth-private-key", "oauth-public-key"]

  runtime_roles = concat([
    "roles/secretmanager.secretAccessor",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/cloudtrace.agent",
  ], var.extra_runtime_roles)

  plain_env = merge({
    DRUPAL_DB_SSL = "1"
  }, var.extra_env)

  shared_secret_env = {
    DRUPAL_DB_HOST           = "db-host"
    DRUPAL_DB_USER           = local.db_secret_user
    DRUPAL_DB_PASSWORD       = local.db_secret_pass
    DRUPAL_DB_NAME           = local.db_secret_name
    DRUPAL_HASH_SALT         = "${var.app_name}-hash-salt"
    DRUPAL_OAUTH_PRIVATE_KEY = "${var.app_name}-oauth-private-key"
    DRUPAL_OAUTH_PUBLIC_KEY  = "${var.app_name}-oauth-public-key"
  }

  bootstrap_secret_env = merge(local.shared_secret_env, {
    DRUPAL_ADMIN_PASS           = "${var.app_name}-admin-pass"
    DRUPAL_CANVAS_CLIENT_SECRET = "${var.app_name}-canvas-client-secret"
  })

  jobs = {
    bootstrap = { command = var.bootstrap_command, secret_env = local.bootstrap_secret_env, timeout = "1800s" }
    cron      = { command = var.cron_command, secret_env = local.shared_secret_env, timeout = "600s" }
  }
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

resource "google_secret_manager_secret" "app" {
  for_each  = toset(local.app_secret_kinds)
  project   = var.project_id
  secret_id = "${var.app_name}-${each.value}"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_iam_member" "app_runtime_read" {
  for_each  = google_secret_manager_secret.app
  project   = var.project_id
  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.identity.runtime_sa_email}"
}

resource "google_storage_bucket" "files" {
  project                     = var.project_id
  name                        = "${var.project_id}-${var.app_name}-files"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}

resource "google_storage_bucket_iam_member" "files_object_admin" {
  bucket = google_storage_bucket.files.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.identity.runtime_sa_email}"
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
    timeout                          = "300s"
    execution_environment            = "EXECUTION_ENVIRONMENT_GEN2"

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    volumes {
      name = "files"
      gcs {
        bucket    = google_storage_bucket.files.name
        read_only = false
      }
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

      startup_probe {
        http_get {
          path = var.startup_probe_path
          port = 8080
        }
        period_seconds    = 1
        timeout_seconds   = 1
        failure_threshold = 60
      }

      volume_mounts {
        name       = "files"
        mount_path = var.files_mount_path
      }

      dynamic "env" {
        for_each = local.plain_env
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = local.shared_secret_env
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value
              version = "latest"
            }
          }
        }
      }
    }
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

  depends_on = [module.db, google_secret_manager_secret.app]
}

resource "google_cloud_run_v2_service_iam_member" "public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.this.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_v2_job" "this" {
  for_each = local.jobs
  provider = google-beta
  project  = var.project_id
  name     = "${var.app_name}-${each.key}"
  location = var.region

  deletion_protection = false

  template {
    template {
      service_account       = module.identity.runtime_sa_email
      timeout               = each.value.timeout
      max_retries           = 0
      execution_environment = "EXECUTION_ENVIRONMENT_GEN2"

      volumes {
        name = "files"
        gcs {
          bucket    = google_storage_bucket.files.name
          read_only = false
        }
      }

      containers {
        image = var.image
        args  = each.value.command

        resources {
          limits = {
            cpu    = var.cpu
            memory = var.memory
          }
        }

        volume_mounts {
          name       = "files"
          mount_path = var.files_mount_path
        }

        dynamic "env" {
          for_each = local.plain_env
          content {
            name  = env.key
            value = env.value
          }
        }

        dynamic "env" {
          for_each = each.value.secret_env
          content {
            name = env.key
            value_source {
              secret_key_ref {
                secret  = env.value
                version = "latest"
              }
            }
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [template[0].template[0].containers[0].image]
  }

  depends_on = [module.db, google_secret_manager_secret.app]
}

resource "google_cloud_run_v2_job_iam_member" "cron_invoker" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_job.this["cron"].name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${module.identity.runtime_sa_email}"
}

resource "google_cloud_scheduler_job" "cron" {
  project          = var.project_id
  region           = var.region
  name             = "${var.app_name}-cron"
  description      = "drush cron for ${var.app_name}"
  schedule         = var.cron_schedule
  time_zone        = "UTC"
  attempt_deadline = "180s"

  http_target {
    uri         = "https://run.googleapis.com/v2/projects/${var.project_id}/locations/${var.region}/jobs/${google_cloud_run_v2_job.this["cron"].name}:run"
    http_method = "POST"

    oauth_token {
      service_account_email = module.identity.runtime_sa_email
    }
  }
}

resource "google_cloud_scheduler_job" "warm" {
  project          = var.project_id
  region           = var.region
  name             = "${var.app_name}-warm"
  description      = "Keeps ${var.app_name} warm between visitors"
  schedule         = var.warm_schedule
  time_zone        = "UTC"
  attempt_deadline = "60s"

  http_target {
    uri         = "${google_cloud_run_v2_service.this.uri}${var.warm_path}"
    http_method = "GET"
  }
}
