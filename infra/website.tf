# Bucket to store website
resource "google_storage_bucket" "website" {
  name     = "chrisyoung-io"
  location = var.region

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }

  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}

# Make new objects public
resource "google_storage_default_object_access_control" "website_read" {
  bucket = google_storage_bucket.website.name
  role   = "READER"
  entity = "allUsers"
}

resource "google_dns_managed_zone" "external_zone" {
  name        = "external-dns-zone"
  project     = var.project_id
  dns_name    = "${local.external_dns_name}."
  description = "DNS zone for ${local.external_dns_name}"
}

# Reserve an external IP
resource "google_compute_global_address" "website" {
  name     = "website-lb-ip"
}


# Add the IP to the DNS
resource "google_dns_record_set" "website" {
  name         = "www.${google_dns_managed_zone.external_zone.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.external_zone.name
  rrdatas      = [google_compute_global_address.website.address]
}

# Add the bucket as a CDN backend
resource "google_compute_backend_bucket" "website" {
  name        = "website-backend"
  description = "Contains files needed by the website"
  bucket_name = google_storage_bucket.website.name
  enable_cdn  = true
}

# Create HTTPS certificate
resource "google_compute_managed_ssl_certificate" "website" {
  name     = "website-cert"
  project          = var.project_id
  managed {
    domains = [google_dns_record_set.website.name]
  }
}

# GCP URL MAP
resource "google_compute_url_map" "website" {
  name            = "website-url-map"
  default_service = google_compute_backend_bucket.website.self_link
}

# GCP target proxy
resource "google_compute_target_https_proxy" "website" {
  name             = "website-target-proxy"
  url_map          = google_compute_url_map.website.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.website.self_link]
}

# GCP forwarding rule
resource "google_compute_global_forwarding_rule" "default" {
  name                  = "website-forwarding-rule"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.website.address
  ip_protocol           = "TCP"
  port_range            = "443"
  target                = google_compute_target_https_proxy.website.self_link
}

///

resource "google_compute_url_map" "http_to_https" {
  name = "http-to-https"
  description = "Redirect http traffic to https"

  default_url_redirect {
    https_redirect = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query = false
  }
}

resource "google_compute_target_http_proxy" "http_to_https" {
  name    = "http-to-https"
  url_map = google_compute_url_map.http_to_https.self_link
}

resource "google_compute_global_forwarding_rule" "http_to_https" {
  name       = "http-to-https"
  ip_address = google_compute_global_address.website.address
  port_range = "80"
  target     = google_compute_target_http_proxy.http_to_https.self_link
}

/// Apex redirect

# Bucket to store website
resource "google_storage_bucket" "website_apex" {
  name     = "chrisyoung-io-apex"
  location = var.region

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }

  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}

# Make new objects public
resource "google_storage_default_object_access_control" "website_apex_read" {
  bucket = google_storage_bucket.website_apex.name
  role   = "READER"
  entity = "allUsers"
}

# Reserve an external IP
resource "google_compute_global_address" "website_apex" {
  name     = "website-apex-lb-ip"
}


# Add the IP to the DNS
resource "google_dns_record_set" "website_apex" {
  name         = "${google_dns_managed_zone.external_zone.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.external_zone.name
  rrdatas      = [google_compute_global_address.website_apex.address]
}

# Add the bucket as a CDN backend
resource "google_compute_backend_bucket" "website_apex" {
  name        = "website-apex-backend"
  description = "Contains files needed by the website"
  bucket_name = google_storage_bucket.website_apex.name
  enable_cdn  = true
}

# Create HTTPS certificate
resource "google_compute_managed_ssl_certificate" "website_apex" {
  name     = "website-apex-cert"
  project  = var.project_id
  managed {
    domains = [google_dns_record_set.website_apex.name]
  }
}

# GCP URL MAP
resource "google_compute_url_map" "website_apex" {
  name            = "website-apex-url-map"
  default_service = google_compute_backend_bucket.website_apex.self_link
}

# GCP target proxy
resource "google_compute_target_https_proxy" "website_apex" {
  name             = "website-apex-target-proxy"
  url_map          = google_compute_url_map.website_apex.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.website_apex.self_link]
}

# GCP forwarding rule
resource "google_compute_global_forwarding_rule" "website_apex" {
  name                  = "website-apex-forwarding-rule"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.website_apex.address
  ip_protocol           = "TCP"
  port_range            = "443"
  target                = google_compute_target_https_proxy.website_apex.self_link
}

///

resource "google_compute_url_map" "http_to_https_apex" {
  name = "http-to-https-apex"
  description = "Redirect http traffic to https"

  default_url_redirect {
    https_redirect = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query = false
  }
}

resource "google_compute_target_http_proxy" "http_to_https_apex" {
  name    = "http-to-https-apex"
  url_map = google_compute_url_map.http_to_https_apex.self_link
}

resource "google_compute_global_forwarding_rule" "http_to_https_apex" {
  name       = "http-to-https-apex"
  ip_address = google_compute_global_address.website_apex.address
  port_range = "80"
  target     = google_compute_target_http_proxy.http_to_https_apex.self_link
}
