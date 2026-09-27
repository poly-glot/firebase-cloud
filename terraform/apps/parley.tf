module "parley" {
  source = "../modules/wordpress-cloudrun"

  project_id    = var.project_id
  region        = var.region
  app_name      = "parley"
  github_org    = var.github_org
  github_repo   = "parley"
  database_name = "parley"
  wif_pool_id   = var.wif_pool_id
  wif_pool_name = var.wif_pool_name
}
