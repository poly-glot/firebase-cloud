# ─────────────────────────────────────────────────────────────
# amazingcar-2003 — Static marketing site (pre-rendered HTML)
# ─────────────────────────────────────────────────────────────
# Migrated from OCI OKE. Pre-rendered from PHP templates and
# served entirely from Firebase Hosting — no Cloud Run, no DB.
# Reservation form uses Formspree (client-side POST).
# ─────────────────────────────────────────────────────────────

module "amazingcar_2003_identity" {
  source = "../modules/app-identity"

  project_id    = var.project_id
  app_name      = "amazingcar-2003"
  github_org    = var.github_org
  github_repo   = "amazingcar-2003"
  wif_pool_id   = var.wif_pool_id
  wif_pool_name = var.wif_pool_name

  ci_cd_roles = [
    "roles/firebasehosting.admin",
    "roles/firebase.admin",
    "roles/iam.serviceAccountUser",
    "roles/serviceusage.serviceUsageConsumer",
  ]

  runtime_roles = [
    "roles/logging.logWriter",
  ]
}

module "amazingcar_2003_hosting" {
  source = "../modules/hosting"

  project_id = var.project_id
  site_id    = "amazingcar-2003"
}

resource "google_firebase_hosting_custom_domain" "amazingcar_2003" {
  provider      = google-beta
  project       = var.project_id
  site_id       = module.amazingcar_2003_hosting.site_id
  custom_domain = "amazingcar-2003.junaid.guru"

  wait_dns_verification = false
}