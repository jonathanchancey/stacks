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

variable "name" {
  type    = string
  default = "vm name"
}

variable "node_name" {
  type = string
}

variable "description" {
  type    = string
  default = "Managed by Terraform"
}

variable "tags" {
  type    = list(string)
  default = ["terraform"]
}

variable "vm_id" {
  type    = number
  default = null
}

variable "datastore_id" {
  type      = string
  default   = "local"
  sensitive = true
}

variable "username" {
  type = string
}

variable "password" {
  type      = string
  sensitive = true
}

variable "sshkeys" {
  type        = list(string)
  description = "sshkeys"
}

variable "dns_domain" {
  type    = string
  default = ""
}

variable "dns_servers" {
  type    = list(string)
  default = []
}

variable "network_device_vlan_id" {
  type    = number
  default = 0
}

variable "disk_size" {
  type    = number
  default = 20
}

variable "tpm_state" {
  type    = string
  default = "v2.0"
}

variable "clone" {
  type    = set(map(bool))
  default = []
}

variable "clone_vm_id" {
  type    = number
  default = null
}

variable "memory_dedicated" {
  type    = number
  default = 4096
}

variable "cpu_cores" {
  type    = number
  default = 2
}

variable "template" {
  type    = bool
  default = false
}

variable "reboot" {
  type    = bool
  default = true
}

variable "additional_disk_size" {
  type        = number
  default     = 0
  description = "Size of the additional disk"
}

variable "additional_disk_file_format" {
  type        = string
  default     = ""
  description = "File format for the additional disk. May need to be raw for LVM"
}

variable "additional_disk_datastore_id" {
  type        = string
  default     = ""
  description = "Datastore ID for the additional disk"
}

variable "tpm_state_datastore_id" {
  type        = string
  default     = "local-lvm"
  description = "tpm_state_datastore_id"
}

variable "hostpci" {
  description = "Configuration for hostpci device"
  type = object({
    device = string
    id     = string
    pcie   = bool
    rombar = bool
    xvga   = bool
  })
  default = null
}

variable "cloud_image_id" {
  type        = string
  default     = ""
  description = "Alternatively, pass the id of a cloud image terraform resource"
}
