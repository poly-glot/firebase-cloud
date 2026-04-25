output "app_entry" {
  description = "Entry to add to the mysql-app-catalog locals; consumed by personal-cloud terraform"
  value = {
    database = var.database_name
    sa_email = var.runtime_sa_email
  }
}
