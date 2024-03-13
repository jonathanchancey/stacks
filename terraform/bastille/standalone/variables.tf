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
  description = "The username for Proxmox Virtual Environment API (example: root@pam)"
}

variable "vm_server_username" {
  type        = string
  description = "The username for the server node(s)"
}

variable "vm_server_password" {
  type        = string
  description = "The password for the server node(s)"
  sensitive   = true
}

variable "vm_agent_username" {
  type        = string
  description = "The username for the agent node(s)"
}

variable "vm_agent_password" {
  type        = string
  description = "The password for the agent node(s)"
  sensitive   = true
}

variable "sshkeys" {
  description = "The Public SSH key(s) to add to authorized_hosts on all vms"
}