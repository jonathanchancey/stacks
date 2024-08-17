resource "pihole_dns_record" "record" {
  domain = "okapi.local"
  ip     = "10.10.0.19"
}

resource "pihole_dns_record" "okapi_internal" {
  domain = "okapi.internal"
  ip     = "10.10.0.19"
}
