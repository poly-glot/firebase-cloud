module "boxes" {
  source = "../modules/wordpress-cloudrun"

  project_id    = var.project_id
  region        = var.region
  app_name      = "boxes"
  github_org    = var.github_org
  github_repo   = "boxes"
  database_name = "boxes"
  wif_pool_id   = var.wif_pool_id
  wif_pool_name = var.wif_pool_name

  extra_env = {
    WP_PUBLIC_HOST = "boxes.junaid.guru"
  }
}

module "boxes_hosting" {
  source = "../modules/hosting"

  project_id = var.project_id
  site_id    = "boxes-junaid"
}

resource "google_firebase_hosting_custom_domain" "boxes" {
  provider      = google-beta
  project       = var.project_id
  site_id       = module.boxes_hosting.site_id
  custom_domain = "boxes.junaid.guru"

  wait_dns_verification = false
}

resource "google_project_iam_member" "boxes_ci_firebase" {
  for_each = toset(["roles/firebase.admin", "roles/firebasehosting.admin"])
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${module.boxes.ci_cd_sa_email}"
}
