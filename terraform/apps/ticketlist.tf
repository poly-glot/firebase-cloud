# ─────────────────────────────────────────────────────────────
# ticketlist (ticketlist-zigstore repo) — Observability
# ─────────────────────────────────────────────────────────────
# The Cloud Run service itself is deployed by the app repo's CI
# (`gcloud run deploy`); this file owns the Service Monitoring
# service the Cloud Run console reads SLOs from, its SLOs and the
# burn-rate alert policies that reference them. The log-based
# metrics and the email notification channel were created by the
# app repo's scripts and stay unmanaged; the channel is referenced
# by id. The _Trace observability bucket (europe-west2) was created
# once via the Observability API on 2026-10-27: it is immutable and
# undeletable, and google_observability_bucket needs provider >= 7.
#
# The nightly-stress Cloud Run job and its Scheduler trigger are
# provisioned by the app repo (scripts/stress/provision-nightly.sh);
# this file owns the job's runtime identity and its project roles,
# adopted on 2026-10-27 (import in terraform/imports.tf), the two
# alert policies on the job's outcome, and the k6 generator's
# role-less identity, which the provisioning script requires.
# ─────────────────────────────────────────────────────────────

locals {
  ticketlist_edge   = "ticketlist-edge"
  ticketlist_alerts = "projects/${var.project_id}/notificationChannels/8620435102629150387"
  ticketlist_run    = "resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"${local.ticketlist_edge}\""
  ticketlist_metric = "resource.type=\"cloud_run_revision\""

  ticketlist_slos = {
    availability-999 = {
      display_name = "availability-99.9"
      goal         = 0.999
      good         = "metric.type=\"run.googleapis.com/request_count\" ${local.ticketlist_run} metric.label.\"response_code_class\"!=\"5xx\""
      total        = "metric.type=\"run.googleapis.com/request_count\" ${local.ticketlist_run}"
    }
    journey-success-999 = {
      display_name = "buy-path journey success 99%"
      goal         = 0.99
      good         = "metric.type=\"logging.googleapis.com/user/synthetic_journey_total\" ${local.ticketlist_metric} metric.labels.ok=\"true\""
      total        = "metric.type=\"logging.googleapis.com/user/synthetic_journey_total\" ${local.ticketlist_metric}"
    }
  }

  ticketlist_latency_slos = {
    latency-99-2s = {
      display_name = "latency-99pct-under-2s"
      goal         = 0.99
      filter       = "metric.type=\"run.googleapis.com/request_latencies\" ${local.ticketlist_run}"
      max_ms       = 2000
    }
    journey-latency-99-30s = {
      display_name = "buy-path journey latency 99% < 30s"
      goal         = 0.99
      filter       = "metric.type=\"logging.googleapis.com/user/synthetic_journey_latency\" ${local.ticketlist_metric}"
      max_ms       = 30000
    }
  }

  ticketlist_burn = {
    availability_fast = {
      display_name   = "ticketlist: SLO fast burn (14.4x/1h)"
      condition_name = "burn rate 1h > 14.4"
      slo            = "availability-999"
      lookback       = "3600s"
      rate           = 14.4
      aligned        = false
      doc            = "Availability SLO burning 14.4x — 30d budget gone in ~2 days. Check Cloud Run logs for 'edge handler error', engine reachability via /healthz/, leader writability (agent /status readOnly), and recent deploys."
    }
    availability_slow = {
      display_name   = "ticketlist: SLO slow burn (6x/6h)"
      condition_name = "burn rate 6h > 6"
      slo            = "availability-999"
      lookback       = "21600s"
      rate           = 6
      aligned        = false
      doc            = "Availability SLO burning 6x sustained. Investigate during hours: error mix in Cloud Run logs, replica lag, NLB flow issues."
    }
    journey_fast = {
      display_name   = "journey SLO fast burn 14.4x/1h"
      condition_name = "journey SLO fast burn 14.4x/1h"
      slo            = "journey-success-999"
      lookback       = "3600s"
      rate           = 14.4
      aligned        = true
      doc            = "Buy-path journey SLO (journey-success-999) burning error budget at >14.4x over 3600s. The synthetic prober is failing the buy path. Check the prober logs and the edge."
    }
    journey_slow = {
      display_name   = "journey SLO slow burn 6x/6h"
      condition_name = "journey SLO slow burn 6x/6h"
      slo            = "journey-success-999"
      lookback       = "21600s"
      rate           = 6
      aligned        = true
      doc            = "Buy-path journey SLO (journey-success-999) burning error budget at >6x over 21600s. The synthetic prober is failing the buy path. Check the prober logs and the edge."
    }
  }
}

resource "google_monitoring_service" "ticketlist_edge" {
  project      = var.project_id
  service_id   = "${local.ticketlist_edge}-cloud-run"
  display_name = "ticketlist-edge (Cloud Run)"

  basic_service {
    service_type = "CLOUD_RUN"
    service_labels = {
      service_name = local.ticketlist_edge
      location     = var.region
    }
  }
}

resource "google_monitoring_slo" "ticketlist_ratio" {
  for_each = local.ticketlist_slos

  project             = var.project_id
  service             = google_monitoring_service.ticketlist_edge.service_id
  slo_id              = each.key
  display_name        = each.value.display_name
  goal                = each.value.goal
  rolling_period_days = 30

  request_based_sli {
    good_total_ratio {
      good_service_filter  = each.value.good
      total_service_filter = each.value.total
    }
  }
}

resource "google_monitoring_slo" "ticketlist_latency" {
  for_each = local.ticketlist_latency_slos

  project             = var.project_id
  service             = google_monitoring_service.ticketlist_edge.service_id
  slo_id              = each.key
  display_name        = each.value.display_name
  goal                = each.value.goal
  rolling_period_days = 30

  request_based_sli {
    distribution_cut {
      distribution_filter = each.value.filter
      range {
        max = each.value.max_ms
      }
    }
  }
}

resource "google_monitoring_alert_policy" "ticketlist_burn" {
  for_each = local.ticketlist_burn

  project      = var.project_id
  display_name = each.value.display_name
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = each.value.condition_name

    condition_threshold {
      filter          = "select_slo_burn_rate(\"${google_monitoring_slo.ticketlist_ratio[each.value.slo].name}\", \"${each.value.lookback}\")"
      comparison      = "COMPARISON_GT"
      threshold_value = each.value.rate
      duration        = "0s"

      dynamic "aggregations" {
        for_each = each.value.aligned ? [1] : []
        content {
          alignment_period   = "300s"
          per_series_aligner = "ALIGN_MEAN"
        }
      }
    }
  }

  notification_channels = [local.ticketlist_alerts]

  documentation {
    content   = each.value.doc
    mime_type = "text/markdown"
  }
}

# ── nightly-stress runtime identity ──────────────────────────
# monitoring.editor: snooze the burn-rate alerts for the run window.
# run.developer:     execute the k6 generator jobs and poll them.
# logging.viewer:    read the k6 execution summary and the watchdog's
#                    fleet verdicts for the run window (the job cannot
#                    reach the agents' port 7001 from Cloud Run).

resource "google_service_account" "ticketlist_nightly" {
  project      = var.project_id
  account_id   = "ticketlist-nightly"
  display_name = "ticketlist nightly stress (job runtime)"
}

resource "google_project_iam_member" "ticketlist_nightly" {
  for_each = toset([
    "roles/logging.viewer",
    "roles/monitoring.editor",
    "roles/run.developer",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.ticketlist_nightly.email}"
}

# ── nightly-stress outcome ───────────────────────────────────
# Both policies are defined but paused (enabled = false), so a failed
# or missed night still notifies nobody. Paused 2026-11-15 to stay in
# the free tier: Cloud Monitoring bills alerting from no sooner than
# 2027-09-01 at $0.35 a month per metric reference plus $0.50 per
# million points returned, and a disabled policy is not charged. Set
# both to true to be emailed.
#
# Both policies read Cloud Run's own execution metric, not the job's
# result line, so a night that crashes before it logs still counts.
# The job exits non-zero whenever any gate fails.
#
# "has not passed in a day" is a threshold, not a metric-absence
# condition: absence can look back one day at most, which a job that
# runs every 24 hours would trip daily. A threshold may evaluate 25
# hours (alignment period + duration), so the sum over a 24-hour
# window must stay below 1 for 30 minutes, with missing data counted
# as a breach because the metric writes nothing between executions.

locals {
  ticketlist_nightly_executions = "metric.type=\"run.googleapis.com/job/completed_execution_count\" resource.type=\"cloud_run_job\" resource.label.\"job_name\"=\"nightly-stress\""
  ticketlist_nightly_runbook    = "Read the night's result line in Logs Explorer: `resource.type=\"cloud_run_job\" resource.labels.job_name=\"nightly-stress\" jsonPayload.nightly=\"stress\"`. Its `failures` list names the gate. No line for the night means the job stopped before its last stage; read that execution's stdout."
}

resource "google_monitoring_alert_policy" "ticketlist_nightly_failed" {
  project      = var.project_id
  display_name = "ticketlist: nightly stress failed"
  combiner     = "OR"
  enabled      = false

  conditions {
    display_name = "a nightly-stress execution failed"

    condition_threshold {
      filter          = "${local.ticketlist_nightly_executions} metric.label.\"result\"=\"failed\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "0s"

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_SUM"
      }
    }
  }

  notification_channels = [local.ticketlist_alerts]

  documentation {
    content   = "A nightly-stress execution failed: a gate did not hold, or the job crashed or timed out. ${local.ticketlist_nightly_runbook}"
    mime_type = "text/markdown"
  }
}

resource "google_monitoring_alert_policy" "ticketlist_nightly_stale" {
  project      = var.project_id
  display_name = "ticketlist: nightly stress has not passed in a day"
  combiner     = "OR"
  enabled      = false

  conditions {
    display_name = "no succeeded nightly-stress execution in 24h30m"

    condition_threshold {
      filter                  = "${local.ticketlist_nightly_executions} metric.label.\"result\"=\"succeeded\""
      comparison              = "COMPARISON_LT"
      threshold_value         = 1
      duration                = "1800s"
      evaluation_missing_data = "EVALUATION_MISSING_DATA_ACTIVE"

      aggregations {
        alignment_period   = "86400s"
        per_series_aligner = "ALIGN_SUM"
      }
    }
  }

  notification_channels = [local.ticketlist_alerts]

  documentation {
    content   = "No nightly-stress execution has succeeded for more than a day: last night failed, or Cloud Scheduler never started it (check the `nightly-stress` scheduler job in europe-west2). ${local.ticketlist_nightly_runbook}"
    mime_type = "text/markdown"
  }
}

# ── k6 load generator identity ───────────────────────────────
# The k6 Cloud Run job only sends HTTP to the public edge, so its
# runtime identity holds no roles. Without one it ran as the default
# compute service account, which holds Editor on the project, on an
# image pulled from Docker Hub.

resource "google_service_account" "ticketlist_k6" {
  project      = var.project_id
  account_id   = "ticketlist-k6"
  display_name = "ticketlist k6 load generator (holds no roles)"
}
