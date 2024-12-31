## ============================================================================
##  __  __ _ _              _   _ _
## |  \/  (_) | ___ __ ___ | |_(_) | __
## | |\/| | | |/ / '__/ _ \| __| | |/ /
## | |  | | |   <| | | (_) | |_| |   <
## |_|  |_|_|_|\_\_|  \___/ \__|_|_|\_\
## ============================================================================

## ============================================================================
## RouterOS Variables
## ============================================================================


variable "mikrotik_router_username" {
  type        = string
  default     = "admin"
  description = "The username to authenticate against the RouterOS API on the RB5009."
}
variable "mikrotik_router_password" {
  type        = string
  description = "The password to authenticate against the RouterOS API on the RB5009."
  sensitive   = true
}
variable "mikrotik_router_url" {
  type        = string
  description = "The URL for the RouterOS API on the RB5009."
}
variable "mikrotik_router_insecure_skip_tls_verify" {
  type        = bool
  default     = true
  description = "Whether or not to check for certificate validity"
}

## ============================================================================
## Cloudflare Variables
## ============================================================================

variable "cloudflare_token" {
  type        = string
  description = "The token to authenticate against the Cloudflare API."
  sensitive   = true
}
