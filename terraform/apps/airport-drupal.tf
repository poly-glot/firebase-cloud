module "airport_drupal" {
  source = "../modules/drupal-cloudrun"

  project_id    = var.project_id
  region        = var.region
  app_name      = "airport-drupal"
  github_org    = var.github_org
  github_repo   = "airport-drupal"
  database_name = "airport_drupal"
  wif_pool_id   = var.wif_pool_id
  wif_pool_name = var.wif_pool_name

  bootstrap_command = ["meridian-bootstrap"]

  extra_env = {
    DRUPAL_PUBLIC_HOST = "airport.junaid.guru"
  }
}

module "airport_drupal_hosting" {
  source = "../modules/hosting"

  project_id = var.project_id
  site_id    = "airport-drupal-junaid"
}

resource "google_firebase_hosting_custom_domain" "airport_drupal" {
  provider      = google-beta
  project       = var.project_id
  site_id       = module.airport_drupal_hosting.site_id
  custom_domain = "airport.junaid.guru"

  wait_dns_verification = false
}

resource "google_project_iam_member" "airport_drupal_ci_firebase" {
  for_each = toset(["roles/firebase.admin", "roles/firebasehosting.admin"])
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${module.airport_drupal.ci_cd_sa_email}"
}
