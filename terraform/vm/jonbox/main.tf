module "vm" {
  source = "../../modules/proxmox-vm-basic"

  for_each = local.vm_configs

  # individual configuration
  name                         = each.value.name
  vm_id                        = each.value.vm_id
  memory_dedicated             = each.value.memory_dedicated
  cpu_cores                    = each.value.cpu_cores
  disk_size                    = each.value.disk_size
  hostpci                      = try(each.value.hostpci, null)
  network_device_vlan_id       = each.value.network_device_vlan_id
  description                  = each.value.description
  tags                         = each.value.tags
  node_name                    = each.value.node_name
  datastore_id                 = each.value.datastore_id
  dns_domain                   = each.value.dns_domain
  reboot                       = each.value.reboot
  virtual_environment_endpoint = each.value.virtual_environment_endpoint
  virtual_environment_password = each.value.virtual_environment_password
  virtual_environment_username = each.value.virtual_environment_username
  tpm_state_datastore_id       = each.value.tpm_state_datastore_id

  # variables likely to be common but might change
  sshkeys  = var.sshkeys
  username = var.username
  password = var.password
}

resource "proxmox_virtual_environment_download_file" "cloud_image" {
  content_type = local.common_config.cloud_image_content_type
  datastore_id = local.common_config.cloud_image_datastore_id
  node_name    = local.common_config.cloud_image_node_name

  # you may download this image locally on your workstation and then use the local path instead of the remote URL
  url       = local.common_config.cloud_image_url
  file_name = local.common_config.cloud_image_file_name

  # you may also use the SHA256 checksum of the image to verify its integrity
  checksum           = local.common_config.cloud_image_checksum
  checksum_algorithm = local.common_config.cloud_image_checksum_algorithm
}
