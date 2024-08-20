# Define a local variable for common configurations
locals {
  common_config = {
    description                  = "Managed by Terraform"
    tags                         = ["debian", "terraform"]
    node_name                    = "TARS"
    cloud_image_node_name        = "TARS"
    datastore_id                 = "cornfield"
    cloud_image_datastore_id     = "local"
    dns_domain                   = "internal"
    reboot                       = false
    cloud_image_url              = "https://cloud.debian.org/images/cloud/bookworm/20240717-1811/debian-12-generic-amd64-20240717-1811.qcow2"
    cloud_image_file_name        = "debian-12-generic-amd64-20240717-1811.img"
    cloud_image_checksum         = ""
    virtual_environment_endpoint = var.virtual_environment_endpoint
    virtual_environment_password = var.virtual_environment_password
    virtual_environment_username = var.virtual_environment_username
    tpm_state_datastore_id       = "local"
  }

  # Define VMs
  vms = {
    pocket = {
      name                   = "pocket"
      vm_id                  = 132
      memory_dedicated       = 4096
      cpu_cores              = 4
      disk_size              = 10
      network_device_vlan_id = 131
      fqdn                   = "pocket.internal"
      ip_config = {
        ipv6_address = "dhcp"
        ipv6_gateway = ""
      }
    }
    # Add more VMs as needed
    # another_vm = {
    #   name              = "another-vm"
    #   vm_id             = 133
    #   memory_dedicated  = 2048
    #   cpu_cores         = 2
    #   disk_size         = 20
    #   fqdn              = "another-vm.internal"
    #   network_device_vlan_id = 131
    #   ip_config = {
    #     ipv6_address = "dhcp"
    #     ipv6_gateway = ""
    #   }
    # }
  }
}

module "vm" {
  source = "../../modules/proxmox-vm-cloudconfig"

  for_each = local.vms

  # Individual Configuration
  name                   = each.value.name
  vm_id                  = each.value.vm_id
  memory_dedicated       = each.value.memory_dedicated
  cpu_cores              = each.value.cpu_cores
  disk_size              = each.value.disk_size
  fqdn                   = each.value.fqdn
  network_device_vlan_id = each.value.network_device_vlan_id
  ip_config              = each.value.ip_config

  # Common Configuration
  description                  = local.common_config.description
  tags                         = local.common_config.tags
  node_name                    = local.common_config.node_name
  cloud_image_node_name        = local.common_config.cloud_image_node_name
  datastore_id                 = local.common_config.datastore_id
  cloud_image_datastore_id     = local.common_config.cloud_image_datastore_id
  dns_domain                   = local.common_config.dns_domain
  reboot                       = local.common_config.reboot
  cloud_image_url              = local.common_config.cloud_image_url
  cloud_image_file_name        = local.common_config.cloud_image_file_name
  cloud_image_checksum         = local.common_config.cloud_image_checksum
  virtual_environment_endpoint = local.common_config.virtual_environment_endpoint
  virtual_environment_password = local.common_config.virtual_environment_password
  virtual_environment_username = local.common_config.virtual_environment_username
  tpm_state_datastore_id       = local.common_config.tpm_state_datastore_id

  # Variables likely to be common but might change
  sshkeys  = var.sshkeys
  username = var.username
  password = var.password
}
