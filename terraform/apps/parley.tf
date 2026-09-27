module "parley" {
  source = "../modules/wordpress-cloudrun"

  project_id    = var.project_id
  region        = var.region
  app_name      = "parley"
  github_org    = var.github_org
  github_repo   = "parley"
  database_name = "parley"
  wif_pool_id   = var.wif_pool_id
  wif_pool_name = var.wif_pool_name

  extra_env = {
    WP_PUBLIC_HOST = "parley.junaid.guru"
  }
}

# ── Firebase Hosting: parley.junaid.guru → Cloud Run ────────
# Hosting forwards no cookie except __session, so wp-admin stays on the
# run.app URL; the public site is anonymous. firebase.json in the app repo
# rewrites ** to the service; wp-config honours X-Forwarded-Host only when
# it equals the WP_PUBLIC_HOST env above.
module "parley_hosting" {
  source = "../modules/hosting"

  project_id = var.project_id
  site_id    = "parley-junaid"
}

resource "google_firebase_hosting_custom_domain" "parley" {
  provider      = google-beta
  project       = var.project_id
  site_id       = module.parley_hosting.site_id
  custom_domain = "parley.junaid.guru"

  wait_dns_verification = false
}

resource "google_project_iam_member" "parley_ci_firebase" {
  for_each = toset(["roles/firebase.admin", "roles/firebasehosting.admin"])
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${module.parley.ci_cd_sa_email}"
}
