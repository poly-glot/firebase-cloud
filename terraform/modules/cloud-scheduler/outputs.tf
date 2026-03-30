output "job_names" {
  description = "Map of scheduler job names"
  value       = { for k, v in google_cloud_scheduler_job.jobs : k => v.name }
}