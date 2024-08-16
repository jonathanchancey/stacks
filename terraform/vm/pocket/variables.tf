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

# variable "ip_config" {
#   description = "IP configuration for the VM"
#   type = object({
#     ipv4_address = optional(string)
#     ipv4_gateway = optional(string)
#     ipv6_address = optional(string)
#     ipv6_gateway = optional(string)
#   })
#   default = null
# }
