module "flyvipcms_net_identity" {
  source = "../modules/app-identity"

  project_id    = var.project_id
  app_name      = "flyvipcms-net"
  github_org    = var.github_org
  github_repo   = "flyvipcms_net"
  wif_pool_id   = var.wif_pool_id
  wif_pool_name = var.wif_pool_name

  ci_cd_roles = [
    "roles/run.admin",
    "roles/artifactregistry.writer",
    "roles/iam.serviceAccountUser",
    "roles/serviceusage.serviceUsageConsumer",
  ]

  runtime_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/cloudtrace.agent",
  ]
}

module "flyvipcms_net_db" {
  source = "../modules/app-with-mysql"

  project_id       = var.project_id
  app_name         = "flyvipcms-net"
  database_name    = "flyvipcms_net"
  runtime_sa_email = module.flyvipcms_net_identity.runtime_sa_email
}

resource "google_secret_manager_secret" "flyvipcms_net_admin_password" {
  project   = var.project_id
  secret_id = "flyvipcms-net-admin-password"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_iam_member" "flyvipcms_net_runtime_admin_password_read" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.flyvipcms_net_admin_password.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.flyvipcms_net_identity.runtime_sa_email}"
}

locals {
  flyvipcms_net_db_secrets = {
    DB_HOST = "db-host"
    DB_NAME = "flyvipcms-net-db-name"
    DB_PASS = "flyvipcms-net-db-pass"
    DB_USER = "flyvipcms-net-db-user"
  }
}

resource "google_cloud_run_v2_service" "flyvipcms_net" {
  provider = google-beta
  project  = var.project_id
  name     = "flyvipcms-net"
  location = var.region

  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"

  template {
    service_account                  = module.flyvipcms_net_identity.runtime_sa_email
    max_instance_request_concurrency = 10

    scaling {
      min_instance_count = 0
      max_instance_count = 2
    }

    containers {
      image = "us-docker.pkg.dev/cloudrun/container/hello"

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
        name  = "ASPNETCORE_FORWARDEDHEADERS_ENABLED"
        value = "true"
      }

      env {
        name  = "SKIP_MIGRATIONS"
        value = "1"
      }

      dynamic "env" {
        for_each = local.flyvipcms_net_db_secrets
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

  depends_on = [module.flyvipcms_net_db]
}

resource "google_cloud_run_v2_service_iam_member" "flyvipcms_net_public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.flyvipcms_net.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_v2_job" "flyvipcms_net_migrate" {
  provider = google-beta
  project  = var.project_id
  name     = "flyvipcms-net-migrate"
  location = var.region

  deletion_protection = false

  template {
    template {
      service_account       = module.flyvipcms_net_identity.runtime_sa_email
      max_retries           = 0
      timeout               = "600s"
      execution_environment = "EXECUTION_ENVIRONMENT_GEN2"

      containers {
        image = "us-docker.pkg.dev/cloudrun/container/job:latest"
        args  = ["migrate"]

        dynamic "env" {
          for_each = local.flyvipcms_net_db_secrets
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

        env {
          name = "ADMIN_PASSWORD"
          value_source {
            secret_key_ref {
              secret  = google_secret_manager_secret.flyvipcms_net_admin_password.secret_id
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

  lifecycle {
    ignore_changes = [template[0].template[0].containers[0].image]
  }

  depends_on = [
    module.flyvipcms_net_db,
    google_secret_manager_secret_iam_member.flyvipcms_net_runtime_admin_password_read,
  ]
}

resource "google_firebase_hosting_site" "flyvipcms_net" {
  provider = google-beta
  project  = var.project_id
  site_id  = "flyvipcms-net"
}

resource "google_firebase_hosting_version" "flyvipcms_net" {
  provider = google-beta
  site_id  = google_firebase_hosting_site.flyvipcms_net.site_id

  config {
    rewrites {
      glob = "**"
      run {
        service_id = google_cloud_run_v2_service.flyvipcms_net.name
        region     = var.region
      }
    }
  }

  depends_on = [google_cloud_run_v2_service.flyvipcms_net]
}

resource "google_firebase_hosting_release" "flyvipcms_net" {
  provider     = google-beta
  site_id      = google_firebase_hosting_site.flyvipcms_net.site_id
  version_name = google_firebase_hosting_version.flyvipcms_net.name
  message      = "Route all traffic to Cloud Run"
}

resource "google_firebase_hosting_custom_domain" "flyvipcms_net" {
  provider      = google-beta
  project       = var.project_id
  site_id       = google_firebase_hosting_site.flyvipcms_net.site_id
  custom_domain = "flyvipcms-net.junaid.guru"

  wait_dns_verification = false
}
