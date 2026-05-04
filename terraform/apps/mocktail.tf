# ─────────────────────────────────────────────────────────────
# Mocktail — Angular SPA + Zig collab WS + Deno email-auth/AI
# ─────────────────────────────────────────────────────────────
# Frontend → Firebase Hosting (mocktail.junaid.guru, mocktail.web.app)
# /api/email-auth/**, /api/ai/**, /api/images/** → mocktail-email-auth (Deno, standard)
# /api/**                                       → mocktail (Zig, single-threaded epoll reactor)
# Auth: Firebase Identity Platform (passwordless email link via Resend)
# DB:   named Firestore "mocktail" (NOT (default))
#
# Spec: mocktail/docs/superpowers/specs/2026-05-04-mocktail-firebase-cloud-onboarding-design.md
# Load-bearing flags on the inline mocktail Cloud Run service: see comments below.
# ─────────────────────────────────────────────────────────────

module "mocktail_identity" {
  source        = "../modules/app-identity"
  project_id    = var.project_id
  app_name      = "mocktail"
  github_org    = var.github_org
  github_repo   = "mocktail"
  wif_pool_id   = var.wif_pool_id
  wif_pool_name = var.wif_pool_name

  runtime_roles = [
    "roles/datastore.user",                 # Firestore via WIF (FIRESTORE_USE_TLS=true)
    "roles/firebaseauth.admin",             # mint custom tokens for email-link flow
    "roles/secretmanager.secretAccessor",   # future-proofing; not currently consumed
    "roles/iam.serviceAccountTokenCreator", # Admin SDK signBlob (createCustomToken)
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/cloudtrace.agent",
  ]
}

module "mocktail_firestore" {
  source        = "../modules/firestore-databases"
  project_id    = var.project_id
  region        = var.region
  database_name = "mocktail"
}

module "mocktail_hosting" {
  source     = "../modules/hosting"
  project_id = var.project_id
  site_id    = "mocktail"
}

resource "google_firebase_hosting_custom_domain" "mocktail" {
  provider              = google-beta
  project               = var.project_id
  site_id               = module.mocktail_hosting.site_id
  custom_domain         = "mocktail.junaid.guru"
  wait_dns_verification = false
}

# ── Cloud Run: mocktail-email-auth (Deno, standard) ─────────
module "mocktail_email_auth_cloud_run" {
  source                = "../modules/cloud-run"
  project_id            = var.project_id
  region                = var.region
  service_name          = "mocktail-email-auth"
  service_account_email = module.mocktail_identity.runtime_sa_email
  image                 = "${var.region}-docker.pkg.dev/${var.project_id}/firebase-cloud/mocktail-email-auth:latest"
  health_path           = "/healthz"

  env_vars = {
    PROJECT_ID          = var.project_id
    APP_DOMAIN          = "mocktail.junaid.guru"
    FROM_EMAIL          = "Mocktail <me@junaid.guru>"
    RESEND_API_KEY      = var.resend_api_key
    UNSPLASH_ACCESS_KEY = var.unsplash_access_key
    GEMINI_API_KEY      = var.gemini_api_key
    GEMINI_MODEL        = "gemini-2.5-flash"
    # GEMINI_ENABLED is NOT set — service short-circuits callGemini() in code.
    # To enable later: add GEMINI_ENABLED = "true" here and apply.
  }

  depends_on = [module.mocktail_identity]
}

# ── Cloud Run: mocktail (Zig collab) ────────────────────────
# INLINED rather than module-driven. Every flag below is load-bearing — see
# memory.md and 2026-05-04-collab-self-kill-design.md. Don't optimize.
resource "google_cloud_run_v2_service" "mocktail" {
  provider            = google-beta
  project             = var.project_id
  name                = "mocktail"
  location            = var.region
  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = module.mocktail_identity.runtime_sa_email

    scaling {
      min_instance_count = 0 # scale-to-zero when idle (cost saving)
      max_instance_count = 1 # CORRECTNESS: in-memory pending buffer would
      # diverge across instances. Don't raise.
    }

    max_instance_request_concurrency = 1000 # reactor handles 2048 conns/instance.
    # Default 80 forces scale-out before saturation.
    timeout               = "3600s" # cap per-WS-session at Cloud Run max.
    execution_environment = "EXECUTION_ENVIRONMENT_GEN2"

    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/firebase-cloud/mocktail:latest"

      resources {
        limits   = { cpu = "1", memory = "256Mi" }
        cpu_idle = false # CORRECTNESS: --no-cpu-throttling.
        # 1s epoll tick + self-kill timer require CPU between WS frames.
        startup_cpu_boost = true
      }

      ports {
        container_port = 8080
      }

      env {
        name  = "FIRESTORE_USE_TLS"
        value = "true"
      }
      env {
        name  = "FIRESTORE_DB"
        value = "mocktail"
      }
      env {
        name  = "KEEPALIVE_SECONDS"
        value = "1800"
      }
      env {
        name  = "FLUSH_MAX_INTERVAL_SECONDS"
        value = "600"
      }
      env {
        name  = "FLUSH_QUIESCENCE_MILLIS"
        value = "5000"
      }

      startup_probe {
        # Plain GET — no Accept header. Service responds `ok\n` to /healthz.
        # Don't change to a JSON probe (memory.md "What NOT to do").
        http_get {
          path = "/healthz"
        }
        initial_delay_seconds = 5
        period_seconds        = 10
        failure_threshold     = 3
        timeout_seconds       = 3
      }
      # No liveness probe: a stuck reactor should die via self-kill
      # (KEEPALIVE_SECONDS), not be force-restarted mid-flush.
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image, # CI/CD swaps :sha at deploy time
      traffic,
    ]
  }

  depends_on = [module.mocktail_identity, module.mocktail_firestore]
}

resource "google_cloud_run_v2_service_iam_member" "mocktail_public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.mocktail.name
  role     = "roles/run.invoker"
  member   = "allUsers" # auth happens at app layer; Hosting /api/** rewrite fronts the service
}
