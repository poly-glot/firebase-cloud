module "legal" {
  source = "../modules/wordpress-cloudrun"

  project_id    = var.project_id
  region        = var.region
  app_name      = "legal"
  github_org    = var.github_org
  github_repo   = "legal"
  database_name = "legal"
  wif_pool_id   = var.wif_pool_id
  wif_pool_name = var.wif_pool_name

  extra_env = {
    WP_PUBLIC_HOST = "legal.junaid.guru"
  }
}

# ── Firebase Hosting: legal.junaid.guru → Cloud Run ─────────
# Same hybrid as parley: Hosting rewrites ** to the service and forwards
# only the __session cookie, so wp-admin stays on the run.app URL and
# wp-config honours X-Forwarded-Host only when it equals WP_PUBLIC_HOST.
module "legal_hosting" {
  source = "../modules/hosting"

  project_id = var.project_id
  site_id    = "legal-junaid"
}

resource "google_firebase_hosting_custom_domain" "legal" {
  provider      = google-beta
  project       = var.project_id
  site_id       = module.legal_hosting.site_id
  custom_domain = "legal.junaid.guru"

  wait_dns_verification = false
}

resource "google_project_iam_member" "legal_ci_firebase" {
  for_each = toset(["roles/firebase.admin", "roles/firebasehosting.admin"])
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${module.legal.ci_cd_sa_email}"
}
