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
  default   = "hydra"
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
  default = "local"
}

variable "dns_servers" {
  type    = list(string)
  default = ["10.30.0.1", "1.1.1.1"]
}

variable "ip_config_ipv4" {
  type    = string
  default = "dhcp"
}

variable "ip_config_gateway" {
  type    = string
  default = "10.30.0.1"
}

variable "network_device_vlan_id" {
  type    = number
  default = 30
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

variable "cloud_image_content_type" {
  type    = string
  default = "iso"
}

variable "cloud_image_datastore_id" {
  type    = string
  default = "chimera"
}

variable "cloud_image_node_name" {
  type = string
}

variable "cloud_image_checksum" {
  type        = string
  default     = ""
  description = "SHA256 checksum of cloud image"
}

variable "cloud_image_url" {
  type    = string
  default = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
}

variable "cloud_image_file_name" {
  type    = string
  default = "ubuntu-22.04-server-cloudimg-amd64.img"
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
