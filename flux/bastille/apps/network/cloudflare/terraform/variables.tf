variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}

variable "cloudflare_account_id" {
  type = string
}

variable "state_passphrase" {
  type      = string
  sensitive = true
}
