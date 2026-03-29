output "url" {
  description = "Artifact Registry repository URL"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker.repository_id}"
}

output "repo_id" {
  description = "Artifact Registry repository ID"
  value       = google_artifact_registry_repository.docker.repository_id
}
