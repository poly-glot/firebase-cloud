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
# azadi-helidon: identities, database, hosting site and secret shells were created with gcloud on 2026-10-01
# before this definition existed; adopt them so terraform owns them (and grants the IAM roles) going forward.
import {
  to = module.apps.module.azadi_helidon_identity.google_service_account.ci_cd
  id = "projects/firebase-cloud-491613/serviceAccounts/azadi-helidon-ci-cd@firebase-cloud-491613.iam.gserviceaccount.com"
}

import {
  to = module.apps.module.azadi_helidon_identity.google_service_account.runtime
  id = "projects/firebase-cloud-491613/serviceAccounts/azadi-helidon-runtime@firebase-cloud-491613.iam.gserviceaccount.com"
}

import {
  to = module.apps.module.azadi_helidon_identity.google_iam_workload_identity_pool_provider.github
  id = "projects/firebase-cloud-491613/locations/global/workloadIdentityPools/github-actions-pool/providers/azadi-helidon-github"
}

import {
  to = module.apps.module.azadi_helidon_firestore.google_firestore_database.app
  id = "projects/firebase-cloud-491613/databases/azadi-helidon"
}

import {
  to = module.apps.module.azadi_helidon_hosting.google_firebase_hosting_site.default
  id = "projects/firebase-cloud-491613/sites/azadi-helidon"
}

import {
  to = module.apps.google_secret_manager_secret.azadi_helidon["AZADI_ENCRYPTION_KEY"]
  id = "projects/firebase-cloud-491613/secrets/azadi-helidon-encryption-key"
}

import {
  to = module.apps.google_secret_manager_secret.azadi_helidon["AZADI_ENCRYPTION_SALT"]
  id = "projects/firebase-cloud-491613/secrets/azadi-helidon-encryption-salt"
}

import {
  to = module.apps.google_secret_manager_secret.azadi_helidon["RESEND_API_KEY"]
  id = "projects/firebase-cloud-491613/secrets/azadi-helidon-resend-api-key"
}

import {
  to = module.apps.google_secret_manager_secret.azadi_helidon["STRIPE_API_KEY"]
  id = "projects/firebase-cloud-491613/secrets/azadi-helidon-stripe-api-key"
}

import {
  to = module.apps.google_secret_manager_secret.azadi_helidon["STRIPE_WEBHOOK_SECRET"]
  id = "projects/firebase-cloud-491613/secrets/azadi-helidon-stripe-webhook-secret"
}

import {
  to = module.apps.google_secret_manager_secret.azadi_helidon["VITE_STRIPE_PUBLISHABLE_KEY"]
  id = "projects/firebase-cloud-491613/secrets/azadi-helidon-stripe-publishable-key"
}
