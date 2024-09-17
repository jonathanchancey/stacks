
resource "cloudflare_record" "jonbox-controlplane" {
  zone_id = var.cloudflare_zone_id
  name    = "jonbox-controlplane."
  #   content = "10.131.131.10"
  type = "A"
}

resource "cloudflare_record" "lb" {
  zone_id = var.cloudflare_zone_id
  name    = "lb"
  #   content = "10.131.131.11"
  type = "A"
}

resource "cloudflare_record" "wildcard" {
  zone_id = var.cloudflare_zone_id
  name    = "*"
  content = "*.${var.cloudflare_domain}"
  type    = "CNAME"
}
