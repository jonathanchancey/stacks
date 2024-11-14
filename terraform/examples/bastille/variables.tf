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

variable "clone_vm_id" {
  type    = number
  default = null
}
