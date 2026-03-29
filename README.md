# firebase-cloud

Central infrastructure repo for a shared GCP/Firebase project. Manages all cloud resources via Terraform so that app repos (webhook, etc.) contain zero infrastructure code.

## Architecture

```
firebase-cloud/                     # THIS REPO
├── terraform/
│   ├── main.tf                     # Providers, project setup, shared WIF pool
│   ├── modules/
│   │   ├── project-setup/          # GCP APIs, Firebase, Auth config
│   │   ├── wif-pool/               # Shared Workload Identity Pool
│   │   ├── app-identity/           # Per-app: SA + WIF provider + IAM
│   │   ├── artifact-registry/      # Shared Docker image registry
│   │   ├── firestore-databases/    # Per-app named Firestore database
│   │   ├── hosting/                # Per-app Firebase Hosting site
│   │   ├── cloud-run/              # Per-app Cloud Run service
│   │   └── bigquery/               # Per-app BigQuery dataset
│   ├── apps/
│   │   ├── hooklab.tf              # Hooklab app configuration
│   │   └── _template.tf.example    # Copy this to onboard a new app
│   ├── outputs.tf
│   ├── variables.tf
│   └── terraform.tfvars.example
└── .github/workflows/
    └── terraform.yml               # Plan on PR, apply on merge to main
```

Each app repo (e.g. `webhook`) has **no terraform** — it only uses GitHub secrets produced by this repo (`WIF_PROVIDER`, `GCP_SA_EMAIL`) to deploy via its own CI/CD.

---

## Prerequisites

### Tools

| Tool             | Version   | Install                         |
|------------------|-----------|---------------------------------|
| Terraform        | >= 1.9    | `brew install terraform`        |
| Google Cloud SDK | latest    | `brew install google-cloud-sdk` |
| `gh` CLI         | latest    | `brew install gh`               |

### GCP Project

You need an existing GCP project with billing enabled. If you don't have one:

```bash
gcloud projects create YOUR_PROJECT_ID --name="Firebase Cloud"
gcloud billing projects link YOUR_PROJECT_ID --billing-account=BILLING_ACCOUNT_ID
```

---

## Permissions Required

### For Local Development (your personal account)

Your Google account needs these roles on the GCP project:

| Role                                          | Why                                   |
|-----------------------------------------------|---------------------------------------|
| `roles/owner` **or** the specific roles below | Simplest for initial setup            |
| `roles/iam.workloadIdentityPoolAdmin`         | Create/manage WIF pools and providers |
| `roles/iam.serviceAccountAdmin`               | Create service accounts               |
| `roles/iam.serviceAccountUser`                | Bind SAs to resources                 |
| `roles/resourcemanager.projectIamAdmin`       | Grant IAM roles to SAs                |
| `roles/firebase.admin`                        | Enable Firebase, manage hosting sites |
| `roles/serviceusage.serviceUsageAdmin`        | Enable GCP APIs                       |
| `roles/run.admin`                             | Create Cloud Run services             |
| `roles/artifactregistry.admin`                | Create AR repos                       |
| `roles/bigquery.admin`                        | Create datasets                       |
| `roles/storage.admin`                         | Create TF state bucket                |

**How to grant:**

```bash
# Option A: Owner (simplest for solo/small team)
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="user:you@example.com" \
  --role="roles/owner"

# Option B: Granular roles (recommended for teams)
for role in \
  roles/iam.workloadIdentityPoolAdmin \
  roles/iam.serviceAccountAdmin \
  roles/iam.serviceAccountUser \
  roles/resourcemanager.projectIamAdmin \
  roles/firebase.admin \
  roles/serviceusage.serviceUsageAdmin \
  roles/run.admin \
  roles/artifactregistry.admin \
  roles/bigquery.admin \
  roles/storage.admin; do
  gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="user:you@example.com" \
    --role="$role"
done
```

### For GitHub Actions CI/CD (infra SA)

The `firebase-cloud` repo itself needs a bootstrap service account for Terraform to run in CI. This SA is separate from the per-app SAs.

```bash
# Create the infra SA
gcloud iam service-accounts create terraform-infra \
  --project=YOUR_PROJECT_ID \
  --display-name="Terraform Infrastructure CI/CD"

# Grant it the same roles as above
for role in \
  roles/iam.workloadIdentityPoolAdmin \
  roles/iam.serviceAccountAdmin \
  roles/iam.serviceAccountUser \
  roles/resourcemanager.projectIamAdmin \
  roles/firebase.admin \
  roles/serviceusage.serviceUsageAdmin \
  roles/run.admin \
  roles/artifactregistry.admin \
  roles/bigquery.admin \
  roles/storage.admin; do
  gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:terraform-infra@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="$role"
done
```

Then set up WIF for this repo (the infra repo itself):

```bash
# Create a separate WIF provider for the infra repo
# (or reuse the pool created by Terraform on first local apply)
# After first local apply, the pool exists. Then:

gcloud iam service-accounts add-iam-policy-binding \
  terraform-infra@YOUR_PROJECT_ID.iam.gserviceaccount.com \
  --project=YOUR_PROJECT_ID \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/YOUR_ORG/firebase-cloud"

# Create a WIF provider for this repo
gcloud iam workload-identity-pools providers create-oidc infra-github \
  --project=YOUR_PROJECT_ID \
  --location=global \
  --workload-identity-pool=github-actions-pool \
  --display-name="Infra Repo GitHub OIDC" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \
  --attribute-condition="assertion.repository == 'YOUR_ORG/firebase-cloud'"
```

Then set these GitHub secrets on the `firebase-cloud` repo:

| Secret               | Value                                                                                                       |
|----------------------|-------------------------------------------------------------------------------------------------------------|
| `INFRA_WIF_PROVIDER` | `projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions-pool/providers/infra-github` |
| `INFRA_GCP_SA_EMAIL` | `terraform-infra@YOUR_PROJECT_ID.iam.gserviceaccount.com`                                                   |

---

## Running Locally

### 1. Authenticate

```bash
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
```

### 2. Bootstrap the state bucket (first time only)

```bash
gsutil mb -p YOUR_PROJECT_ID -l us-central1 gs://YOUR_PROJECT_ID-tf-state
gsutil versioning set on gs://YOUR_PROJECT_ID-tf-state
```

Then uncomment the `backend "gcs"` block in `terraform/main.tf`.

### 3. Configure variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 4. Init, plan, apply

```bash
terraform init
terraform plan       # Review changes
terraform apply      # Apply changes
```

### 5. Copy outputs to app repos

After apply, copy the per-app outputs into each app repo's GitHub secrets:

```bash
# Get hooklab outputs
terraform output hooklab_wif_provider
terraform output hooklab_gcp_sa_email

# Set them on the webhook repo
gh secret set WIF_PROVIDER -R YOUR_ORG/webhook --body "$(terraform output -raw hooklab_wif_provider)"
gh secret set GCP_SA_EMAIL -R YOUR_ORG/webhook --body "$(terraform output -raw hooklab_gcp_sa_email)"
```

---

## Running in CI/CD (GitHub Actions)

The workflow (`.github/workflows/terraform.yml`) handles this automatically:

| Event             | Action                                                      |
|-------------------|-------------------------------------------------------------|
| PR opened/updated | `terraform plan` — posts plan as PR comment                 |
| Push to `main`    | `terraform apply` — applies changes, outputs to job summary |

### Setup checklist

1. [ ] Create GCP project with billing
2. [ ] Run locally once to bootstrap (state bucket, WIF pool)
3. [ ] Create `terraform-infra` SA (see Permissions section)
4. [ ] Create WIF provider for this repo (see Permissions section)
5. [ ] Set `INFRA_WIF_PROVIDER` and `INFRA_GCP_SA_EMAIL` as GitHub secrets
6. [ ] Uncomment `backend "gcs"` in `main.tf`
7. [ ] Create a `production` environment in GitHub repo settings (for apply approval)

---

## Onboarding a New App

1. Copy `terraform/apps/_template.tf.example` to `terraform/apps/<app-name>.tf`
2. Fill in the app name, GitHub repo, and modules needed
3. Open a PR — review the Terraform plan
4. Merge — CI applies, creates SA + WIF + resources
5. Copy outputs to the app repo's GitHub secrets:

```bash
gh secret set WIF_PROVIDER -R YOUR_ORG/new-app-repo \
  --body "$(terraform output -raw newapp_wif_provider)"
gh secret set GCP_SA_EMAIL -R YOUR_ORG/new-app-repo \
  --body "$(terraform output -raw newapp_gcp_sa_email)"
```

6. The app repo's CI/CD now works with keyless auth to the shared GCP project.

---

## Importing Existing Resources

If you already have resources created manually or from another Terraform state:

```bash
# Import the WIF pool
terraform import module.wif_pool.google_iam_workload_identity_pool.github \
  projects/YOUR_PROJECT_ID/locations/global/workloadIdentityPools/github-actions-pool

# Import a service account
terraform import module.hooklab_identity.google_service_account.ci_cd \
  projects/YOUR_PROJECT_ID/serviceAccounts/hooklab-ci-cd@YOUR_PROJECT_ID.iam.gserviceaccount.com

# Import Firestore database
terraform import module.hooklab_firestore.google_firestore_database.app \
  projects/YOUR_PROJECT_ID/databases/hooklab

# Import Cloud Run service
terraform import module.hooklab_cloud_run.google_cloud_run_v2_service.default \
  projects/YOUR_PROJECT_ID/locations/us-central1/services/hooklab-api

# After all imports, verify:
terraform plan  # Should show no changes
```

---

## Gotchas

1. **WIF Pool limit**: Max 100 providers per pool. Fine for <100 apps.
2. **WIF Pool soft-delete**: Deleted pools have a 30-day grace period. Cannot reuse the same ID.
3. **IAM eventual consistency**: New SA + WIF bindings take up to 60s to propagate. First deploys may fail.
4. **Terraform state chicken-and-egg**: GCS bucket must exist before `terraform init` with remote backend. Bootstrap locally first.
5. **Terraform apply ordering**: Must apply here before an app repo's first CD run.
6. **`attribute_condition` is exact match**: Case-sensitive. Must match exactly what GitHub sends.
7. **Cross-repo secret rotation**: Rotating SA/WIF breaks app repos until secrets are updated.
