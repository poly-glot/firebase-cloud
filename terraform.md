# Terraform: Firebase-Cloud Infrastructure & Multi-App Isolation

## Architecture Overview

A separate `firebase-cloud` repo manages all GCP/Firebase infrastructure via Terraform. Each app (like this webhook repo) keeps only its application code and CI/CD workflows.

```
firebase-cloud/                    # Infra-only repo
├── terraform/
│   ├── main.tf                    # GCP project, APIs, shared infra
│   ├── modules/
│   │   ├── project-setup/         # APIs, Firebase enable, Firestore
│   │   ├── wif-pool/              # ONE shared Workload Identity Pool
│   │   ├── app-identity/          # Per-app: SA + WIF provider + IAM
│   │   ├── artifact-registry/
│   │   ├── firestore-databases/   # Named database per app
│   │   └── shared-infra/          # DNS zone, VPC, etc.
│   ├── apps/
│   │   ├── hooklab.tf             # module "hooklab" { source = "../modules/app-identity" }
│   │   ├── app-two.tf             # module "app_two" { source = "../modules/app-identity" }
│   │   └── ...
│   ├── outputs.tf
│   └── variables.tf
└── .github/workflows/
    └── terraform.yml              # Plan on PR, apply on merge

webhook/                           # App repo (this repo)
├── .github/workflows/
│   ├── ci.yml
│   └── cd.yml                     # Uses WIF_PROVIDER + GCP_SA_EMAIL from firebase-cloud
├── client/
├── server/
├── functions/
└── (NO terraform/)
```

## Migration Steps

1. Create `firebase-cloud` repo
2. Move `webhook/terraform/` into the new repo, restructure into modules
3. `terraform import` existing resources (WIF pool, SAs, APIs, etc.) into the new state
4. Verify with `terraform plan` — should show no changes
5. Set up GCS backend for remote state with versioning + locking
6. Delete `webhook/terraform/` from this repo
7. Onboard future apps by adding a `.tf` file in `apps/`

## Service Account Strategy

**Per-app SA + per-app WIF provider** (recommended over shared SA):

- Each app gets its own service account and WIF provider
- WIF provider `attribute_condition` is pinned to the app's specific GitHub repo
- Least privilege — can revoke one app without touching others
- Audit trail per app

```hcl
# modules/app-identity/main.tf

variable "app_name"      {}
variable "github_org"    {}
variable "github_repo"   {}
variable "project_id"    {}
variable "wif_pool_name" {}
variable "roles"         { type = set(string) }

resource "google_service_account" "ci_cd" {
  account_id   = "${var.app_name}-ci-cd"
  display_name = "${var.app_name} GitHub Actions CI/CD"
}

resource "google_project_iam_member" "roles" {
  for_each = var.roles
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.ci_cd.email}"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = var.wif_pool_name
  workload_identity_pool_provider_id = "${var.app_name}-github"
  attribute_condition = "assertion.repository == '${var.github_org}/${var.github_repo}'"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }
  oidc { issuer_uri = "https://token.actions.githubusercontent.com" }
}

resource "google_service_account_iam_member" "wif_binding" {
  service_account_id = google_service_account.ci_cd.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${var.wif_pool_name}/attribute.repository/${var.github_org}/${var.github_repo}"
}
```

Onboarding a new app:

```hcl
# apps/hooklab.tf
module "hooklab" {
  source         = "../modules/app-identity"
  app_name       = "hooklab"
  github_org     = "your-org"
  github_repo    = "webhook"
  project_id     = var.project_id
  wif_pool_name  = module.wif_pool.pool_name
  roles          = ["roles/firebase.admin", "roles/run.admin", "roles/artifactregistry.writer"]
}
```

## Distributing Credentials to App Repos

Each app repo needs two GitHub secrets: `WIF_PROVIDER` and `GCP_SA_EMAIL`.

| Method | How | Trade-off |
|---|---|---|
| Manual | Copy Terraform outputs into GitHub repo secrets | Simplest, but manual rotation |
| GitHub Terraform provider | Terraform sets secrets directly on each repo | Cleanest, requires GitHub PAT with repo admin scope |
| Secret Manager + fetch | Store in GCP Secret Manager, fetch in workflow | More moving parts |

## App Isolation

### Cloud Functions: `codebase` isolation

Each app **must** declare a `codebase` in `firebase.json`. Without this, `firebase deploy --only functions` will **delete** functions from other apps.

```json
{
  "functions": [
    {
      "source": "functions",
      "codebase": "hooklab",
      "ignore": ["node_modules", ".git"]
    }
  ]
}
```

The `codebase` field tells the Firebase CLI to only manage functions belonging to that codebase — functions from other codebases are left untouched during deploy.

Additionally, prefix all function names with the app identifier:

```ts
// webhook repo
export const hooklab_onRequestCreated = onDocumentCreated(...);
export const hooklab_processWebhook = onRequest(...);

// app-two repo
export const apptwo_onOrderPlaced = onDocumentCreated(...);
```

### Firestore: Named databases (one per app)

Firebase supports multiple named databases. Each app gets its own, providing separate rules, indexes, and data with zero coordination.

```hcl
# firebase-cloud terraform
resource "google_firestore_database" "hooklab" {
  project     = var.project_id
  name        = "hooklab"
  location_id = var.region
  type        = "FIRESTORE_NATIVE"
}

resource "google_firestore_database" "apptwo" {
  project     = var.project_id
  name        = "apptwo"
  location_id = var.region
  type        = "FIRESTORE_NATIVE"
}
```

App code connects to its named database:

```ts
const db = getFirestore(app, "hooklab");
```

Benefits:
- Separate security rules per database
- Separate indexes per database
- No collection name collisions
- Independent backup/restore

### Firebase Hosting: Separate sites

Each app gets its own `site_id`. Terraform creates the hosting site resource, the app repo deploys to it. No collision risk.

### Cloud Run: Separate services

Each app deploys its own named service (`hooklab-api`, `apptwo-api`). No collision.

### Artifact Registry: Path-based isolation

Share one AR repo, use different image paths:

```
us-central1-docker.pkg.dev/PROJECT/shared-ar/hooklab-api:latest
us-central1-docker.pkg.dev/PROJECT/shared-ar/apptwo-api:latest
```

### Secret Manager: Prefix + scoped IAM

Prefix secret names per app and scope access via IAM per service account:

```hcl
resource "google_secret_manager_secret_iam_member" "hooklab_secrets" {
  secret_id = google_secret_manager_secret.hooklab_stripe_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.hooklab.sa_email}"
}
```

## Collision Risk Summary

| Resource | Risk | Isolation mechanism |
|---|---|---|
| Cloud Functions | **High** — flat namespace, deploy deletes others | `codebase` field in `firebase.json` |
| Firestore data | **High** — shared collections, single rules file | Named databases (one per app) |
| Firestore rules | **High** — last deploy wins | Named databases (own rules each) |
| Firestore indexes | **Medium** — merge conflicts | Named databases |
| Hosting | None | Separate `site_id` per app |
| Cloud Run | None | Separate service name per app |
| Storage rules | **High** — single rules file | Prefix paths + separate buckets |
| Secrets | **Medium** — naming overlap | Prefix + scoped IAM per SA |
| BigQuery | Low | Separate datasets per app |

## Gotchas

1. **WIF Pool limit**: Max 100 providers per pool. One shared pool works for <100 apps.
2. **WIF Pool deletion is soft-delete**: 30-day grace period. Cannot recreate with same ID during that window.
3. **Terraform state bootstrap**: GCS bucket for state must exist before `terraform init`. Create manually with `gsutil mb`.
4. **IAM eventual consistency**: New SA + WIF bindings can take up to 60s to propagate. First deploys after infra changes may fail.
5. **Cross-repo secret rotation**: Rotating SA or WIF provider breaks all app repos until their secrets are updated.
6. **`attribute_condition` is exact match**: Case-sensitive, must match exactly what GitHub sends. Forks won't match.
7. **Terraform apply ordering**: Must `terraform apply` in `firebase-cloud` before an app repo's first CD run.
8. **`codebase` is mandatory**: Without it, deploying functions from one app silently deletes functions from all other apps. This is the single most dangerous collision vector.
9. **Default Firestore database**: If apps share `(default)`, any `firebase deploy` that includes firestore rules will overwrite the entire ruleset. Named databases eliminate this.
