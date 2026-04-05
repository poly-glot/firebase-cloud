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

  # CI/CD SA needs cloudscheduler.admin on top of the default roles to create
  # and update the scheduler jobs Firebase auto-provisions for onSchedule
  # functions (generateLocationPool, cleanup).
  ci_cd_roles = [
    "roles/firebase.admin",
    "roles/run.admin",
    "roles/iam.serviceAccountUser",
    "roles/artifactregistry.writer",
    "roles/cloudbuild.builds.builder",
    "roles/firebasehosting.admin",
    "roles/secretmanager.secretAccessor",
    "roles/serviceusage.serviceUsageConsumer",
    "roles/cloudscheduler.admin",
  ]

  runtime_roles = [
    "roles/firebasedatabase.admin",
    "roles/firebaseauth.admin",
    "roles/secretmanager.secretAccessor",
    "roles/aiplatform.user",
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

# Allow the runtime SA to sign blobs as itself. Required by
# getAuth().createCustomToken() in the login/createGame functions — the Firebase
# Admin SDK calls iam.serviceAccounts.signBlob to mint custom tokens.
resource "google_service_account_iam_member" "openguessr_runtime_token_creator" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${module.openguessr_identity.runtime_sa_email}"
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${module.openguessr_identity.runtime_sa_email}"

  depends_on = [module.openguessr_identity]
}

# Allow the CI/CD SA to deploy functions that run as the runtime SA.
# roles/iam.serviceAccountUser is already granted project-wide to the CI/CD SA
# by the app-identity module, so nothing extra is needed for actAs here.

# Grant runtime SA access to the secret (used by Cloud Functions at runtime)
resource "google_secret_manager_secret_iam_member" "openguessr_maps_key_runtime_access" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.openguessr_google_maps_api_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.openguessr_identity.runtime_sa_email}"

  depends_on = [module.openguessr_identity]
}

# Grant CI/CD SA admin on the secret (needed by `firebase deploy` with defineSecret:
#   - secretmanager.secrets.get (verify secret exists)
#   - secretmanager.secrets.setIamPolicy (bind runtime SA to the function)
#   - secretmanager.versions.add (update secret value on deploy)
# The project-level secretmanager.secretAccessor role only grants versions.access.
resource "google_secret_manager_secret_iam_member" "openguessr_maps_key_cicd_admin" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.openguessr_google_maps_api_key.secret_id
  role      = "roles/secretmanager.admin"
  member    = "serviceAccount:${module.openguessr_identity.ci_cd_sa_email}"

  depends_on = [module.openguessr_identity]
}
