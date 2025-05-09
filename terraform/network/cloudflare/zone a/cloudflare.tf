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

resource "cloudflare_record" "oauth" {
  zone_id = var.cloudflare_zone_id
  name    = "oauth"
  content = var.traefik_ip
  type    = "A"
}

resource "cloudflare_record" "wild-x" {
  zone_id = var.cloudflare_zone_id
  name    = "*.x"
  content = var.nginx_internal_ip
  type    = "A"
}

resource "cloudflare_record" "wild-root" {
  zone_id = var.cloudflare_zone_id
  name    = "*"
  content = var.nginx_internal_ip
  type    = "A"
}

resource "cloudflare_record" "gitea_ssh" {
  zone_id = var.cloudflare_zone_id
  name    = "git"
  content = var.gitea_ssh_internal_ip
  type    = "A"
}

resource "cloudflare_record" "skytxt" {
  zone_id = var.cloudflare_zone_id
  name    = "_atproto"
  content = "did=did:plc:f2ablw5m3ashhpydt6u7h2rx"
  type    = "TXT"
}
