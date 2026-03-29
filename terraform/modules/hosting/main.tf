# ─────────────────────────────────────────────────────────────
# Firebase Hosting Site (per-app)
# ─────────────────────────────────────────────────────────────

resource "google_firebase_hosting_site" "default" {
  provider = google-beta
  project  = var.project_id
  site_id  = var.site_id
}

resource "google_firebase_hosting_version" "default" {
  provider = google-beta
  site_id  = google_firebase_hosting_site.default.site_id

  config {
    rewrites {
      glob = "**"
      path = "/index.html"
    }

    headers {
      glob = "**"
      headers = {
        "X-Content-Type-Options" = "nosniff"
        "X-Frame-Options"        = "DENY"
        "X-XSS-Protection"       = "1; mode=block"
        "Referrer-Policy"        = "strict-origin-when-cross-origin"
        "Permissions-Policy"     = "geolocation=(), microphone=(), camera=()"
      }
    }

    headers {
      glob = "**/*.@(js|css|svg|png|jpg|jpeg|gif|ico|woff2)"
      headers = {
        "Cache-Control" = "public, max-age=31536000, immutable"
      }
    }
  }
}
