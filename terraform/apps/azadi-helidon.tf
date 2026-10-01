# ─────────────────────────────────────────────────────────────
# Azadi Finance Portal (Helidon)
# ─────────────────────────────────────────────────────────────
# Helidon 4 SE port of the Azadi customer portal. Own Firebase
# Hosting site, Cloud Run service, Datastore database and
# Secret Manager secrets; the app pipeline only moves images.
# Resources created by hand on 2026-10-01 are adopted through
# import blocks in terraform/imports.tf.
# ─────────────────────────────────────────────────────────────

module "azadi_helidon_identity" {
  source = "../modules/app-identity"

  project_id    = var.project_id
  app_name      = "azadi-helidon"
  github_org    = var.github_org
  github_repo   = "azadi-helidon"
  wif_pool_id   = var.wif_pool_id
  wif_pool_name = var.wif_pool_name
}

module "azadi_helidon_firestore" {
  source = "../modules/firestore-databases"

  project_id    = var.project_id
  region        = var.region
  database_name = "azadi-helidon"
  database_type = "DATASTORE_MODE"
}

module "azadi_helidon_hosting" {
  source = "../modules/hosting"

  project_id = var.project_id
  site_id    = "azadi-helidon"
}

# ── Secrets (shells only; values added with `gcloud secrets versions add`) ──

locals {
  azadi_helidon_secrets = {
    AZADI_ENCRYPTION_KEY        = "azadi-helidon-encryption-key"
    AZADI_ENCRYPTION_SALT       = "azadi-helidon-encryption-salt"
    RESEND_API_KEY              = "azadi-helidon-resend-api-key"
    STRIPE_API_KEY              = "azadi-helidon-stripe-api-key"
    STRIPE_WEBHOOK_SECRET       = "azadi-helidon-stripe-webhook-secret"
    VITE_STRIPE_PUBLISHABLE_KEY = "azadi-helidon-stripe-publishable-key"
  }

  azadi_helidon_env = {
    GCP_PROJECT_ID = var.project_id
    FIRESTORE_DB   = module.azadi_helidon_firestore.database_name
    USE_ADC        = "true"
    DEMO_MODE      = "true"
  }
}

resource "google_secret_manager_secret" "azadi_helidon" {
  for_each = local.azadi_helidon_secrets

  project   = var.project_id
  secret_id = each.value
  replication {
    auto {}
  }
}

# ── Cloud Run service ───────────────────────────────────────

module "azadi_helidon_cloud_run" {
  source = "../modules/cloud-run"

  project_id            = var.project_id
  region                = var.region
  service_name          = "azadi-helidon-api"
  service_account_email = module.azadi_helidon_identity.runtime_sa_email
  memory                = "256Mi"
  max_instances         = 1
  session_affinity      = true
  health_path           = "/actuator/health"
  env_vars              = local.azadi_helidon_env
  secret_env_vars       = local.azadi_helidon_secrets

  depends_on = [module.azadi_helidon_identity, google_secret_manager_secret.azadi_helidon]
}

# ── Database migration job (seeder; idempotent, executed by the app pipeline) ──

resource "google_cloud_run_v2_job" "azadi_helidon_migrate" {
  provider = google-beta
  project  = var.project_id
  name     = "azadi-helidon-api-migrate"
  location = var.region

  deletion_protection = false

  template {
    template {
      service_account = module.azadi_helidon_identity.runtime_sa_email
      max_retries     = 0
      timeout         = "300s"

      containers {
        image   = "us-docker.pkg.dev/cloudrun/container/hello"
        command = ["/opt/jre/bin/java"]
        args    = ["-cp", "/app/app.jar:/app/libs/*", "guru.junaid.azadi.seed.DataSeeder"]

        dynamic "env" {
          for_each = local.azadi_helidon_env
          content {
            name  = env.key
            value = env.value
          }
        }

        dynamic "env" {
          for_each = local.azadi_helidon_secrets
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

        resources {
          limits = {
            cpu    = "1"
            memory = "256Mi"
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [template[0].template[0].containers[0].image]
  }

  depends_on = [module.azadi_helidon_identity, google_secret_manager_secret.azadi_helidon]
}
