# ─────────────────────────────────────────────────────────────
# crea8ivedesign — Static design-studio marketing site (pre-rendered HTML)
# ─────────────────────────────────────────────────────────────
# Migrated from legacy PHP hosting. Pre-rendered from PHP templates
# and served entirely from Firebase Hosting — no Cloud Run, no DB.
# Order/contact flows are mock only; no server-side handling.
# ─────────────────────────────────────────────────────────────

module "crea8ivedesign_identity" {
  source = "../modules/app-identity"

  project_id    = var.project_id
  app_name      = "crea8ivedesign"
  github_org    = var.github_org
  github_repo   = "crea8ivedesign"
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

module "crea8ivedesign_hosting" {
  source = "../modules/hosting"

  project_id = var.project_id
  site_id    = "crea8ivedesign"
}

resource "google_firebase_hosting_custom_domain" "crea8ivedesign" {
  provider      = google-beta
  project       = var.project_id
  site_id       = module.crea8ivedesign_hosting.site_id
  custom_domain = "crea8ivedesign.junaid.guru"

  wait_dns_verification = false
}