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

variable "vm_template_username" {
  type = string
}

variable "vm_template_password" {
  type      = string
  sensitive = true
}

variable "vm_template_sshkeys" {
  description = "sshkeys"
}

variable "vm_template_name" {
  type    = string
  default = "vm-template"
}

variable "vm_template_node_name" {
  type = string
}

variable "vm_template_description" {
  type    = string
  default = "Managed by Terraform"
}

variable "vm_template_datastore_id" {
  type      = string
  default   = "hydra"
  sensitive = true
}

variable "vm_template_dns_domain" {
  type    = string
  default = "local"
}

variable "vm_template_dns_servers" {
  type    = list(any)
  default = ["10.30.0.1", "1.1.1.1"]
}

variable "vm_template_ip_config_ipv4" {
  type    = string
  default = "dhcp"
}

variable "vm_template_disk_datastore_id" {
  type    = string
  default = "hydra"
}

variable "vm_template_ip_config_ipv4" {
  type    = string
  default = "dhcp"
}

variable "vm_template_network_device_vlan_id" {
  type    = number
  default = 30
}

variable "vm_instance_name" {
  type = string
}

variable "vm_instance_node_name" {
  type = string
}

variable "vm_instance_description" {
  type    = string
  default = "Managed by Terraform"
}

variable "vm_instance_vm_id" {
  type = string
}

variable "vm_instance_memory_dedicated" {
  type    = number
  default = 4096
}

variable "vm_instance_cpu_cores" {
  type    = number
  default = 2
}

variable "vm_instance_ip_config_ipv4" {
  type = string
}

variable "vm_instance_ip_config_gateway" {
  type    = string
  default = "10.30.0.1"
}

variable "vm_instance_vm_id" {
  type    = string
  default = "dhcp"
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

variable "cloud_image_url" {
  type    = string
  default = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
}

variable "cloud_image_file_name" {
  type    = string
  default = "ubuntu-22.04-server-cloudimg-amd64.img"
}
