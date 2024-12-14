variable "cloudflare_api_token" {
  type        = string
  description = "cloudflare_api_token"
  sensitive   = true
}

variable "cloudflare_zone_id" {
  type    = string
  default = null
}

variable "cloudflare_account_id" {
  type    = string
  default = null
}

variable "cloudflare_domain" {
  type    = string
  default = null
}

variable "traefik_ip" {
  type    = string
  default = null
}

variable "nginx_internal_ip" {
  type    = string
  default = null
}

variable "gitea_ssh_internal_ip" {
  type    = string
  default = null
}
