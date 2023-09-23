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

variable "name" {
  type        = string
  description = "Name of the Proxmox VM"
}

variable "desc" {
  type        = string
  description = "VM description for Proxmox VM"
  default     = "kubernetes"
}

variable "vmid" {
  type        = number
  default     = 0
  description = "VM ID for Proxmox VM"
}

variable "target_node" {
  type        = string
  description = "Proxmox target node"
}

variable "agent" {
  type        = number
  description = "Enable Proxmox guest agent (0 or 1)"
  default     = 0
}

variable "clone_template_name" {
  type        = string
  description = "Name of the template VM to clone from (optional)"
  default     = "debian-12-cloudinit"
}

variable "cores" {
  type        = number
  description = "CPU cores for Proxmox VM"
  default     = 4
}

variable "sockets" {
  type        = number
  description = "CPU sockets for Proxmox VM"
  default     = 1
}

variable "memory" {
  type        = number
  description = "Memory size for Proxmox VM (in MB)"
  default     = 2048
}

variable "os_type" {
  type        = string
  description = "os_type"
  default     = "cloud-init"
}

variable "ipconfig0" {
  type        = string
  description = "ipconfig0"
  default     = "ip=dhcp,gw=192.168.0.1"
}

variable "nameserver" {
  type        = string
  description = "nameserver"
  default     = "192.168.0.3"
}

variable "ssh_user" {
  type        = string
  description = "ssh_user"
  default     = "kube"
}

variable "sshkeys" {
  # type        = string
  description = "sshkeys"
}
