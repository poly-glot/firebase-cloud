# ─────────────────────────────────────────────────────────────
# mysql-app-catalog
# Single contract between firebase-cloud and personal-cloud.
# firebase-cloud writes a JSON map of apps that need OCI MySQL DBs;
# personal-cloud reads it and provisions databases + populates per-app
# secret versions. Adding a new app to this map (and adding a matching
# module "<app>_db" call) is the only edit needed to provision a DB.
# ─────────────────────────────────────────────────────────────

locals {
  mysql_apps = {
    shehryar = module.shehryar_db.app_entry
  }
}

resource "google_secret_manager_secret" "mysql_app_catalog" {
  project   = var.project_id
  secret_id = "mysql-app-catalog"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "mysql_app_catalog" {
  secret      = google_secret_manager_secret.mysql_app_catalog.id
  secret_data = jsonencode(local.mysql_apps)
}

# ─────────────────────────────────────────────────────────────
# Bootstrap IAM: grant personal-cloud's deploy SA reader on the
# secrets it needs to bring up its terraform stack (catalog + admin
# creds + tfstate creds). Managed here rather than in personal-cloud
# to avoid a chicken-and-egg (personal-cloud cannot self-grant the
# access it needs to apply).
# ─────────────────────────────────────────────────────────────

locals {
  personal_cloud_bootstrap_secrets = toset([
    "mysql-app-catalog",
    "db-admin-user",
    "db-admin-pass",
    "oci-tf-aws-access-key-id",
    "oci-tf-aws-secret-access-key",
  ])
}

resource "google_secret_manager_secret_iam_member" "personal_cloud_bootstrap_access" {
  for_each  = local.personal_cloud_bootstrap_secrets
  project   = var.project_id
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.personal_cloud_deploy_sa}"

  depends_on = [google_secret_manager_secret.mysql_app_catalog]
}
