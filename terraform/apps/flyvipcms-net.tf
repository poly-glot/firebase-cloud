module "flyvipcms_net_identity" {
  source = "../modules/app-identity"

  project_id    = var.project_id
  app_name      = "flyvipcms-net"
  github_org    = var.github_org
  github_repo   = "flyvipcms_net"
  wif_pool_id   = var.wif_pool_id
  wif_pool_name = var.wif_pool_name

  ci_cd_roles = [
    "roles/run.admin",
    "roles/artifactregistry.writer",
    "roles/iam.serviceAccountUser",
    "roles/serviceusage.serviceUsageConsumer",
  ]

  runtime_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/cloudtrace.agent",
  ]
}

module "flyvipcms_net_db" {
  source = "../modules/app-with-mysql"

  project_id       = var.project_id
  app_name         = "flyvipcms-net"
  database_name    = "flyvipcms_net"
  runtime_sa_email = module.flyvipcms_net_identity.runtime_sa_email
}

resource "google_secret_manager_secret" "flyvipcms_net_admin_password" {
  project   = var.project_id
  secret_id = "flyvipcms-net-admin-password"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_iam_member" "flyvipcms_net_runtime_admin_password_read" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.flyvipcms_net_admin_password.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.flyvipcms_net_identity.runtime_sa_email}"
}

resource "google_firebase_hosting_site" "flyvipcms_net" {
  provider = google-beta
  project  = var.project_id
  site_id  = "flyvipcms-net"
}

resource "google_firebase_hosting_custom_domain" "flyvipcms_net" {
  provider      = google-beta
  project       = var.project_id
  site_id       = google_firebase_hosting_site.flyvipcms_net.site_id
  custom_domain = "flyvipcms-net.junaid.guru"

  wait_dns_verification = false
}
