resource "cloudflare_record" "coalesce-vip" {
  zone_id = var.cloudflare_zone_id
  name    = "rke2.c"
  content = "10.131.129.10"
  type    = "A"
}

resource "cloudflare_record" "coalesce-istio" {
  zone_id = var.cloudflare_zone_id
  name    = "ist.c"
  content = "10.131.129.12"
  type    = "A"
}

resource "cloudflare_record" "coalesce-istio-webfrontend" {
  zone_id = var.cloudflare_zone_id
  name    = "webfrontend.c"
  content = "10.131.129.12"
  type    = "A"
}

resource "cloudflare_record" "c" {
  zone_id = var.cloudflare_zone_id
  name    = "c"
  content = "10.131.129.11"
  type    = "A"
}

resource "cloudflare_record" "wildcard_c" {
  zone_id = var.cloudflare_zone_id
  name    = "*.c"
  content = "c.${var.cloudflare_domain}"
  type    = "CNAME"
}

resource "cloudflare_record" "dichotomy-vip" {
  zone_id = var.cloudflare_zone_id
  name    = "rke2.d"
  content = "10.131.131.10"
  type    = "A"
}

resource "cloudflare_record" "d" {
  zone_id = var.cloudflare_zone_id
  name    = "d"
  content = "10.131.131.11"
  type    = "A"
}

resource "cloudflare_record" "wildcard_d" {
  zone_id = var.cloudflare_zone_id
  name    = "*.d"
  content = "d.${var.cloudflare_domain}"
  type    = "CNAME"
}
