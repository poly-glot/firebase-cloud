# ─────────────────────────────────────────────────────────────
# Outrun Extinction — multi-campaign static site
# ─────────────────────────────────────────────────────────────
# Next.js static export served entirely from Firebase Hosting —
# no Cloud Run, no DB. One build hosts every campaign under
# /<campaign>/<locale>. Campaign media serves from the public
# bucket firebase-cloud-491613-outrun-media (created by hand,
# uploaded by the app repo's scripts/media-upload.sh; import
# into Terraform pending).
# ─────────────────────────────────────────────────────────────

module "outrun_identity" {
  source = "../modules/app-identity"

  project_id    = var.project_id
  app_name      = "outrun"
  github_org    = var.github_org
  github_repo   = "outrun"
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

module "outrun_hosting" {
  source = "../modules/hosting"

  project_id = var.project_id
  site_id    = "outrun"
}

resource "google_firebase_hosting_custom_domain" "outrun" {
  provider      = google-beta
  project       = var.project_id
  site_id       = module.outrun_hosting.site_id
  custom_domain = "outrun.junaid.guru"

  wait_dns_verification = false
}
