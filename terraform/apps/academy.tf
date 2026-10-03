module "academy" {
  source = "../modules/wordpress-cloudrun"

  project_id    = var.project_id
  region        = var.region
  app_name      = "academy"
  github_org    = var.github_org
  github_repo   = "academy"
  database_name = "academy"
  wif_pool_id   = var.wif_pool_id
  wif_pool_name = var.wif_pool_name

  extra_env = {
    WP_PUBLIC_HOST = "academy.junaid.guru"
  }
}

module "academy_hosting" {
  source = "../modules/hosting"

  project_id = var.project_id
  site_id    = "academy-junaid"
}

resource "google_firebase_hosting_custom_domain" "academy" {
  provider      = google-beta
  project       = var.project_id
  site_id       = module.academy_hosting.site_id
  custom_domain = "academy.junaid.guru"

  wait_dns_verification = false
}

resource "google_project_iam_member" "academy_ci_firebase" {
  for_each = toset(["roles/firebase.admin", "roles/firebasehosting.admin"])
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${module.academy.ci_cd_sa_email}"
}
