variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type      = string
  sensitive = true
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}

variable "sshkeys" {
  # type        = string
  description = "sshkeys"
}

variable "clone_template_name" {
  type        = string
  description = "Name of the template VM to clone from (optional)"
  default     = "debian-12-cloudinit-refined"
}

variable "nameserver" {
  type        = string
  description = "nameserver"
  default     = "1.1.1.1"
}
