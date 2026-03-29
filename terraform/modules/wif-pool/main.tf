# ─────────────────────────────────────────────────────────────
# Shared Workload Identity Pool
# ─────────────────────────────────────────────────────────────
# ONE pool for all apps. Each app gets its own PROVIDER
# (created by the app-identity module) pinned to its repo.
# ─────────────────────────────────────────────────────────────

resource "google_iam_workload_identity_pool" "github" {
  provider = google-beta
  project  = var.project_id

  workload_identity_pool_id = "github-actions-pool"
  display_name              = "GitHub Actions Pool"
  description               = "Shared OIDC pool for all GitHub Actions deployments"
}
