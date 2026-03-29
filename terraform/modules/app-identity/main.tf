# ─────────────────────────────────────────────────────────────
# Per-App Identity: Service Account + WIF Provider + IAM
# ─────────────────────────────────────────────────────────────
# Creates a dedicated SA and WIF provider for each app.
# The WIF provider attribute_condition is pinned to the app's
# specific GitHub repo — other repos cannot impersonate this SA.
# ─────────────────────────────────────────────────────────────

# ── CI/CD Service Account ───────────────────────────────────
resource "google_service_account" "ci_cd" {
  project      = var.project_id
  account_id   = "${var.app_name}-ci-cd"
  display_name = "${var.app_name} GitHub Actions CI/CD"
  description  = "CI/CD SA for ${var.github_org}/${var.github_repo}"
}

resource "google_project_iam_member" "ci_cd_roles" {
  for_each = var.ci_cd_roles

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.ci_cd.email}"
}

# ── Runtime Service Account (Cloud Run) ─────────────────────
resource "google_service_account" "runtime" {
  project      = var.project_id
  account_id   = "${var.app_name}-runtime"
  display_name = "${var.app_name} Cloud Run Runtime"
  description  = "Runtime identity for ${var.app_name} on Cloud Run"
}

resource "google_project_iam_member" "runtime_roles" {
  for_each = var.runtime_roles

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.runtime.email}"
}

# ── WIF Provider (pinned to this app's repo) ────────────────
resource "google_iam_workload_identity_pool_provider" "github" {
  provider = google-beta
  project  = var.project_id

  workload_identity_pool_id          = var.wif_pool_id
  workload_identity_pool_provider_id = "${var.app_name}-github"
  display_name                       = "${var.app_name} GitHub OIDC"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  attribute_condition = "assertion.repository == '${var.github_org}/${var.github_repo}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# ── Allow WIF to impersonate CI/CD SA ───────────────────────
resource "google_service_account_iam_member" "wif_binding" {
  service_account_id = google_service_account.ci_cd.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${var.wif_pool_name}/attribute.repository/${var.github_org}/${var.github_repo}"
}
