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
  type        = string
  description = "VM Name"
}

variable "node_name" {
  type        = string
  description = "Proxmox Node Name"
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
  type        = number
  default     = null
  description = "Proxmox Qemu/KVM unique VM ID"
}

variable "datastore_id" {
  type        = string
  default     = "local"
  description = "Storage kocation for VM disk"
}

variable "username" {
  type        = string
  description = "Username of account to create"

}

variable "password" {
  type        = string
  sensitive   = true
  description = "Password of account to create"
}

variable "sshkeys" {
  type        = list(string)
  description = "sshkeys"
}

variable "dns_domain" {
  type        = string
  default     = ""
  description = "The DNS Domain for the VM. Inheirits from Proxmox host if unset."
}

variable "dns_servers" {
  type        = list(string)
  default     = []
  description = "List of dns servers. Inheirits from Proxmox host if unset"
}

variable "ip_config_ipv4" {
  type        = string
  default     = ""
  description = "The IPv4 address to be assigned to the VM. Leave empty for DHCP."
}

variable "ip_config_gateway" {
  type        = string
  default     = ""
  description = "The IPv4 gateway for the VM. Required if using a static IPv4 address."
}

variable "ip_config_ipv6_address" {
  type        = string
  default     = ""
  description = "The IPv6 address to be assigned to the VM. Leave empty if not using IPv6."
}

variable "ip_config_ipv6_gateway" {
  type        = string
  default     = ""
  description = "The IPv6 gateway for the VM. Required if using a static IPv6 address."
}

variable "network_device_vlan_id" {
  type        = number
  default     = 0
  description = "The VLAN ID for the network device. Set to 0 for untagged."
}

variable "disk_size" {
  type        = number
  default     = 20
  description = "The size of the VM's disk in GB. Defaults to 20 GB."
}

variable "tpm_state" {
  type        = string
  default     = "v2.0"
  description = "The TPM state version to use. Defaults to v2.0."
}

variable "clone" {
  type        = set(map(bool))
  default     = []
  description = "Set of maps indicating whether to clone an existing VM. Leave empty to create a new VM."
}

variable "clone_vm_id" {
  type        = number
  default     = null
  description = "The ID of the VM to clone. Required if 'clone' is set."
}

variable "memory_dedicated" {
  type        = number
  default     = 4096
  description = "The amount of dedicated memory for the VM in MB. Defaults to 4096 MB (4 GB)."
}

variable "cpu_cores" {
  type        = number
  default     = 2
  description = "The number of CPU cores to allocate to the VM. Defaults to 2."
}

variable "template" {
  type        = bool
  default     = false
  description = "Whether this VM should be created as a template. Defaults to false."
}

variable "reboot" {
  type        = bool
  default     = true
  description = "Whether to reboot the VM after creation. Defaults to true."
}

variable "cloud_image_content_type" {
  type        = string
  default     = "iso"
  description = "The content type of the cloud image. Defaults to 'iso'."
}

variable "cloud_image_datastore_id" {
  type        = string
  description = "The ID of the datastore where the cloud image will be stored."
}

variable "cloud_image_node_name" {
  type        = string
  description = "The name of the node where the cloud image will be stored."
}

variable "cloud_image_checksum" {
  type        = string
  default     = ""
  description = "checksum of cloud image for verification."
}

variable "cloud_image_checksum_algorithm" {
  type        = string
  default     = "sha512"
  description = "checksum algorithm"
}

variable "cloud_image_url" {
  type        = string
  description = "The URL from which to download the cloud image."
}

variable "cloud_image_file_name" {
  type        = string
  description = "The file name to use when storing the cloud image."
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

variable "cloud_image_manage_etc_hosts" {
  type        = string
  default     = "true"
  description = "This module will update the contents of the local hosts database (hosts file, usually /etc/hosts) based on the hostname/FQDN specified in config."
}

variable "cloud_image_ssh_pwauth" {
  type        = string
  default     = "false"
  description = "Enables or disables ssh password authentication"
}

variable "cloud_image_package_upgrade" {
  type        = string
  default     = "true"
  description = "Updates packages on first boot, if cloud_image_packages is specified, package_update will be set to true"
}

variable "fqdn" {
  type        = string
  default     = null
  description = "The fully qualified domain name"
}

variable "agent" {
  type        = bool
  default     = true
  description = "Enable the qemu guest agent flag. Do not enable if the agent isn't installed, check the proxmox provider documentation for more details"
}

variable "ip_config" {
  description = "IP configuration for the VM"
  type = object({
    ipv4_address = optional(string)
    ipv4_gateway = optional(string)
    ipv6_address = optional(string)
    ipv6_gateway = optional(string)
  })
  default = null
}

variable "cloud_image_runcmd" {
  type        = list(string)
  default     = ["timedatectl set-timezone UTC", "systemctl enable qemu-guest-agent", "systemctl start qemu-guest-agent", "echo done > /tmp/cloud-config.done"]
  description = "each item will be executed in order at rc.local like level with output to the console. runcmd only runs during the first boot"
}

variable "cloud_image_packages" {
  type        = list(string)
  default     = ["qemu-guest-agent"]
  description = "Install additional packages on first boot"
}

# variable "ansible_group_children" {
#   type        = list(string)
#   description = "Ansible group children for ansible provider"
# }

# variable "ansible_group_name" {
#   type        = string
#   description = "Ansible group name for ansible provider"
# }
