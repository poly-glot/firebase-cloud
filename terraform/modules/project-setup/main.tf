# ─────────────────────────────────────────────────────────────
# GCP Project Setup: Firebase + Required APIs
# ─────────────────────────────────────────────────────────────

resource "google_firebase_project" "default" {
  provider = google-beta
  project  = var.project_id
}

resource "google_project_service" "apis" {
  for_each = toset([
    "firebase.googleapis.com",
    "firebaserules.googleapis.com",
    "firebasehosting.googleapis.com",
    "firestore.googleapis.com",
    "firebasedatabase.googleapis.com",
    "identitytoolkit.googleapis.com",
    "cloudbuild.googleapis.com",
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "dns.googleapis.com",
    "compute.googleapis.com",
    "secretmanager.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "aiplatform.googleapis.com",
    "cloudscheduler.googleapis.com",
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_identity_platform_config" "auth" {
  provider = google-beta
  project  = var.project_id

  sign_in {
    allow_duplicate_emails = false

    anonymous {
      enabled = true
    }

    email {
      enabled           = true
      password_required = true
    }
  }

  depends_on = [google_firebase_project.default]
}
