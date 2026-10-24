data "google_project" "airport" {
  project_id = var.project_id
}

locals {
  airport_run_domain = "${data.google_project.airport.number}.${var.region}.run.app"
  airport_drupal_url = "https://airport-drupal-${local.airport_run_domain}"
  airport_web_url    = "https://airport-web-${local.airport_run_domain}"
}

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
  warm_path         = "/canvas/content-api?requestUri=/home"

  extra_env = {
    DRUPAL_PUBLIC_HOST  = "airport.junaid.guru"
    CANVAS_FRONTEND_URL = local.airport_web_url
  }
}

resource "google_service_account" "airport_web_runtime" {
  project      = var.project_id
  account_id   = "airport-web-runtime"
  display_name = "airport-web runtime"
}

resource "google_project_iam_member" "airport_web_runtime_logs" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.airport_web_runtime.email}"
}

module "airport_web" {
  source = "../modules/cloud-run"

  project_id            = var.project_id
  region                = var.region
  service_name          = "airport-web"
  service_account_email = google_service_account.airport_web_runtime.email
  max_instances         = 2

  env_vars = {
    CANVAS_SITE_URL = local.airport_drupal_url
  }
}

resource "google_cloud_scheduler_job" "airport_web_warm" {
  project          = var.project_id
  region           = var.region
  name             = "airport-web-warm"
  description      = "Keeps airport-web and its page cache warm between visitors"
  schedule         = "*/15 * * * *"
  time_zone        = "UTC"
  attempt_deadline = "60s"

  http_target {
    uri         = "${local.airport_web_url}/"
    http_method = "GET"
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
