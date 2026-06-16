# ─────────────────────────────────────────────────────────────
# Personal Site 2026 — Deno/Fresh SSR portfolio
# ─────────────────────────────────────────────────────────────
# Firebase Hosting fronts a single Cloud Run service that
# server-renders every route. The Hosting CDN honours the app's
# stale-while-revalidate Cache-Control headers (utils/cache.ts);
# /_fresh/ assets stay immutable. No database — pure SSR.
#
# Fast cold start comes from startup_cpu_boost (hardcoded on in the
# cloud-run module) + the compiled Deno binary, not from steady-state
# CPU. So we keep the 1 vCPU default. Scales to zero, capped at 1.
# ─────────────────────────────────────────────────────────────

module "personal_site_identity" {
  source = "../modules/app-identity"

  project_id    = var.project_id
  app_name      = "personal-site-2026"
  github_org    = var.github_org
  github_repo   = "personal-site-2026"
  wif_pool_id   = var.wif_pool_id
  wif_pool_name = var.wif_pool_name

  runtime_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/cloudtrace.agent",
  ]
}

module "personal_site_hosting" {
  source = "../modules/hosting"

  project_id = var.project_id
  site_id    = "personal-site-2026"
}

module "personal_site_cloud_run" {
  source = "../modules/cloud-run"

  project_id            = var.project_id
  region                = var.region
  service_name          = "personal-site-2026"
  service_account_email = module.personal_site_identity.runtime_sa_email

  max_instances = 1
  health_path   = "/"

  # The compiled Deno binary is serving in ~1.7s, yet the module's default probe
  # (initial_delay 5s, period 10s) holds the instance "not ready" for a fixed 5s,
  # pinning every scale-from-zero request at ~5.1s. Probe from t=0 every 1s so a
  # ready instance is picked up in ~1s; failure_threshold keeps a 10s boot budget.
  startup_probe = {
    initial_delay_seconds = 0
    period_seconds        = 1
    failure_threshold     = 10
    timeout_seconds       = 1
  }

  depends_on = [module.personal_site_identity]
}

# ── Custom Domains ──────────────────────────────────────────
# Apex serves the site; www 301-redirects to the apex so there is
# one canonical host. Both need DNS records at the registrar —
# see the personal_site_2026_required_dns output.
resource "google_firebase_hosting_custom_domain" "personal_site_apex" {
  provider      = google-beta
  project       = var.project_id
  site_id       = module.personal_site_hosting.site_id
  custom_domain = "junaid.guru"

  wait_dns_verification = false
}

resource "google_firebase_hosting_custom_domain" "personal_site_www" {
  provider        = google-beta
  project         = var.project_id
  site_id         = module.personal_site_hosting.site_id
  custom_domain   = "www.junaid.guru"
  redirect_target = "junaid.guru"

  wait_dns_verification = false
}