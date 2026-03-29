output "ci_cd_sa_email" {
  description = "CI/CD service account email"
  value       = google_service_account.ci_cd.email
}

output "runtime_sa_email" {
  description = "Runtime (Cloud Run) service account email"
  value       = google_service_account.runtime.email
}

output "wif_provider" {
  description = "Full WIF provider resource name — set as GitHub secret WIF_PROVIDER"
  value       = google_iam_workload_identity_pool_provider.github.name
}
