# ─────────────────────────────────────────────────────────────
# Shared Outputs
# ─────────────────────────────────────────────────────────────
output "project_id" {
  description = "GCP project ID"
  value       = var.project_id
}

output "project_number" {
  description = "GCP project number"
  value       = data.google_project.project.number
}

output "wif_pool_name" {
  description = "Workload Identity Pool full resource name"
  value       = module.wif_pool.pool_name
}

output "artifact_registry_url" {
  description = "Artifact Registry URL"
  value       = module.artifact_registry.url
}

# ─────────────────────────────────────────────────────────────
# Per-App Outputs (populated by apps/*.tf)
# ─────────────────────────────────────────────────────────────
# Each app's outputs (WIF_PROVIDER, GCP_SA_EMAIL, etc.)
# are defined in their respective apps/*.tf files.
