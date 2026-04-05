# ─────────────────────────────────────────────────────────────
# OpenGuessr (openguessr repo) — App Configuration
# ─────────────────────────────────────────────────────────────

# ── Identity: SA + WIF Provider ─────────────────────────────
module "openguessr_identity" {
  source = "../modules/app-identity"

  project_id    = var.project_id
  app_name      = "openguessr"
  github_org    = var.github_org
  github_repo   = "openguessr"
  wif_pool_id   = var.wif_pool_id
  wif_pool_name = var.wif_pool_name

  runtime_roles = [
    "roles/firebasedatabase.admin",
    "roles/firebaseauth.admin",
    "roles/secretmanager.secretAccessor",
    "roles/aiplatform.user",
    "roles/cloudscheduler.admin",
  ]
}

# ── Firebase Hosting ────────────────────────────────────────
module "openguessr_hosting" {
  source = "../modules/hosting"

  project_id = var.project_id
  site_id    = "openguessr"
}

# ── Firebase Realtime Database ──────────────────────────────
# RTDB only supports europe-west1 in Europe (not europe-west2).
# Cloud Functions and other services use europe-west2.
resource "google_firebase_database_instance" "openguessr" {
  provider    = google-beta
  project     = var.project_id
  region      = "europe-west1"
  instance_id = "${var.project_id}-default-rtdb"
  type        = "DEFAULT_DATABASE"
}

# ── Secrets: Google Maps API Key ────────────────────────────
resource "google_secret_manager_secret" "openguessr_google_maps_api_key" {
  project   = var.project_id
  secret_id = "openguessr-GOOGLE_MAPS_API_KEY"

  replication {
    auto {}
  }

  labels = {
    app = "openguessr"
  }
}

resource "google_secret_manager_secret_version" "openguessr_google_maps_api_key" {
  secret      = google_secret_manager_secret.openguessr_google_maps_api_key.id
  secret_data = var.openguessr_google_maps_api_key
}

# Grant runtime SA access to the secret
resource "google_secret_manager_secret_iam_member" "openguessr_maps_key_access" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.openguessr_google_maps_api_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.openguessr_identity.runtime_sa_email}"

  depends_on = [module.openguessr_identity]
}
