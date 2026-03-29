# ─────────────────────────────────────────────────────────────
# Shared Artifact Registry (Docker images for all apps)
# ─────────────────────────────────────────────────────────────
# Apps push to path-based isolation:
#   <region>-docker.pkg.dev/<project>/<repo>/hooklab-api:latest
#   <region>-docker.pkg.dev/<project>/<repo>/apptwo-api:latest
# ─────────────────────────────────────────────────────────────

resource "google_artifact_registry_repository" "docker" {
  provider = google-beta
  project  = var.project_id
  location = var.region

  repository_id = var.repo_id
  format        = "DOCKER"
  description   = "Shared Docker images for firebase-cloud apps"

  cleanup_policy_dry_run = false

  cleanup_policies {
    id     = "keep-recent"
    action = "KEEP"

    most_recent_versions {
      keep_count = 10
    }
  }
}
