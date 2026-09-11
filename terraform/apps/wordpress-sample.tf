module "wordpress_sample_identity" {
  source = "../modules/app-identity"

  project_id    = var.project_id
  app_name      = "wordpress-sample"
  github_org    = var.github_org
  github_repo   = "wordpress-sample"
  wif_pool_id   = var.wif_pool_id
  wif_pool_name = var.wif_pool_name

  ci_cd_roles = [
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

module "wordpress_sample_db" {
  source = "../modules/app-with-mysql"

  project_id       = var.project_id
  app_name         = "wordpress-sample"
  database_name    = "wordpress_sample"
  runtime_sa_email = module.wordpress_sample_identity.runtime_sa_email
}

locals {
  wordpress_sample_ci_db_secrets = [
    "db-host",
    "wordpress-sample-db-user",
    "wordpress-sample-db-pass",
    "wordpress-sample-db-name",
  ]
}

resource "google_secret_manager_secret_iam_member" "wordpress_sample_ci_db_read" {
  for_each  = toset(local.wordpress_sample_ci_db_secrets)
  project   = var.project_id
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.wordpress_sample_identity.ci_cd_sa_email}"

  depends_on = [module.wordpress_sample_db]
}

resource "google_storage_bucket" "wordpress_sample_uploads" {
  project                     = var.project_id
  name                        = "${var.project_id}-wordpress-sample-uploads"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}

resource "google_storage_bucket_iam_member" "wordpress_sample_uploads_object_admin" {
  bucket = google_storage_bucket.wordpress_sample_uploads.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.wordpress_sample_identity.runtime_sa_email}"
}

resource "google_storage_bucket_iam_member" "wordpress_sample_uploads_public_read" {
  bucket = google_storage_bucket.wordpress_sample_uploads.name
  member = "allUsers"
  role   = "roles/storage.objectViewer"
}

resource "google_cloud_run_v2_service" "wordpress_sample" {
  provider = google-beta
  project  = var.project_id
  name     = "wordpress-sample"
  location = var.region

  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"

  template {
    service_account                  = module.wordpress_sample_identity.runtime_sa_email
    max_instance_request_concurrency = 8

    scaling {
      min_instance_count = 0
      max_instance_count = 1
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
            secret  = "wordpress-sample-db-user"
            version = "latest"
          }
        }
      }

      env {
        name = "DB_PASS"
        value_source {
          secret_key_ref {
            secret  = "wordpress-sample-db-pass"
            version = "latest"
          }
        }
      }

      env {
        name = "DB_NAME"
        value_source {
          secret_key_ref {
            secret  = "wordpress-sample-db-name"
            version = "latest"
          }
        }
      }

      env {
        name  = "GCS_UPLOADS_BUCKET"
        value = google_storage_bucket.wordpress_sample_uploads.name
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
    module.wordpress_sample_db,
  ]
}

resource "google_cloud_run_v2_service_iam_member" "wordpress_sample_public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.wordpress_sample.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_scheduler_job" "wordpress_sample_cron" {
  project          = var.project_id
  region           = var.region
  name             = "wordpress-sample-cron"
  description      = "Hourly WordPress cron for wordpress-sample"
  schedule         = "0 * * * *"
  time_zone        = "UTC"
  attempt_deadline = "180s"

  http_target {
    uri         = "${google_cloud_run_v2_service.wordpress_sample.uri}/wp-cron.php?doing_wp_cron"
    http_method = "GET"
  }
}
