resource "pihole_dns_record" "record" {
  domain = "okapi.local"
  ip     = "10.10.0.19"
}

resource "pihole_dns_record" "okapi_internal" {
  domain = "okapi.internal"
  ip     = "10.10.0.19"
}

resource "pihole_dns_record" "lich_internal" {
  domain = "lich-00.internal"
  ip     = "10.10.0.20"
}

resource "pihole_dns_record" "nginx_e_i" {
  domain = "nginx.ephemera.internal"
  ip     = "10.131.102.20"
}

resource "pihole_dns_record" "hubble_e_i" {
  domain = "hubble.ephemera.internal"
  ip     = "10.131.102.20"
}
