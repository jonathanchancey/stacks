resource "cloudflare_record" "navidrome" {
  zone_id = var.cloudflare_zone_id
  name    = "navidrome"
  content = var.traefik_ip
  type    = "A"
}

resource "cloudflare_record" "syncthing" {
  zone_id = var.cloudflare_zone_id
  name    = "syncthing"
  content = var.traefik_ip
  type    = "A"
}
