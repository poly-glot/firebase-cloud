# ─────────────────────────────────────────────────────────────
# thehighlands — Static property development site (pre-rendered HTML)
# ─────────────────────────────────────────────────────────────
# Migrated from legacy PHP hosting. Pre-rendered from PHP templates
# and served entirely from Firebase Hosting — no Cloud Run, no DB.
# Contact form posts to Formspree; no server-side handling.
# ─────────────────────────────────────────────────────────────

module "thehighlands_identity" {
  source = "../modules/app-identity"

  project_id    = var.project_id
  app_name      = "thehighlands"
  github_org    = var.github_org
  github_repo   = "thehighlands"
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

module "thehighlands_hosting" {
  source = "../modules/hosting"

  project_id = var.project_id
  site_id    = "thehighlands"
}

resource "google_firebase_hosting_custom_domain" "thehighlands" {
  provider      = google-beta
  project       = var.project_id
  site_id       = module.thehighlands_hosting.site_id
  custom_domain = "thehighlands.junaid.guru"

  wait_dns_verification = false
}