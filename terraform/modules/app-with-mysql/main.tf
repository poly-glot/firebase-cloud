locals {
  shell_kinds = ["user", "pass", "name"]
}

# Per-app secret shells. Versions are populated by personal-cloud terraform.
resource "google_secret_manager_secret" "shells" {
  for_each  = toset(local.shell_kinds)
  project   = var.project_id
  secret_id = "${var.app_name}-db-${each.value}"
  replication {
    auto {}
  }
}

# Grant the runtime SA reader on each per-app shell.
resource "google_secret_manager_secret_iam_member" "app_shells" {
  for_each  = google_secret_manager_secret.shells
  project   = var.project_id
  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.runtime_sa_email}"
}

# The shared db-host secret is owned out-of-module by mysql-keepalive.tf.
# We just look it up and grant the runtime SA reader on it.
data "google_secret_manager_secret" "db_host" {
  project   = var.project_id
  secret_id = "db-host"
}

resource "google_secret_manager_secret_iam_member" "db_host" {
  project   = var.project_id
  secret_id = data.google_secret_manager_secret.db_host.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.runtime_sa_email}"
}
