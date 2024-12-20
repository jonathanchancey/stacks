variable "virtual_environment_endpoint" {
  type        = string
  description = "The endpoint for the Proxmox Virtual Environment API (example: https://host:port)"
}

variable "virtual_environment_password" {
  type        = string
  description = "The password for the Proxmox Virtual Environment API"
}

variable "virtual_environment_username" {
  type        = string
  description = "The username and realm for the Proxmox Virtual Environment API (example: root@pam)"
}

variable "username" {
  type        = string
  description = "The username and realm for the Proxmox Virtual Environment API (example: root@pam)"
}

variable "password" {
  type        = string
  description = "The username and realm for the Proxmox Virtual Environment API (example: root@pam)"
  sensitive   = true
}

variable "sshkeys" {
  type        = list(string)
  description = "sshkeys"
}

variable "dns_servers" {
  type    = list(string)
  default = []
}

variable "fqdn" {
  type        = string
  default     = null
  description = "The fully qualified domain name"
}

variable "pihole_api_token" {
  type        = string
  description = "pihole_api_token"
  sensitive   = true
}
