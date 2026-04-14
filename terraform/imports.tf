# ─────────────────────────────────────────────────────────────
# Terraform import blocks (root module)
# ─────────────────────────────────────────────────────────────
# Adopts resources created out-of-band so terraform manages
# them going forward. Import blocks only work in the root module,
# hence this file lives here rather than alongside the resource
# definitions.
# ─────────────────────────────────────────────────────────────

# Shared OCI HeatWave MySQL credentials (used by mysql-keepalive and any
# future apps that connect to the shared DB). Values populated via
# `gcloud secrets versions add`; terraform owns only the secret shell.
import {
  to = module.apps.google_secret_manager_secret.db_host
  id = "projects/firebase-cloud-491613/secrets/db-host"
}

import {
  to = module.apps.google_secret_manager_secret.db_user
  id = "projects/firebase-cloud-491613/secrets/db-user"
}

import {
  to = module.apps.google_secret_manager_secret.db_pass
  id = "projects/firebase-cloud-491613/secrets/db-pass"
}