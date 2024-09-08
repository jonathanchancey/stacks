module "vm" {
  source = "../../modules/proxmox-vm-cloudconfig"

  for_each = local.vm_configs

  # individual configuration
  name                         = each.value.name
  vm_id                        = each.value.vm_id
  memory_dedicated             = each.value.memory_dedicated
  cpu_cores                    = each.value.cpu_cores
  disk_size                    = each.value.disk_size
  fqdn                         = try(each.value.fqdn, null)
  hostpci                      = try(each.value.hostpci, null)
  network_device_vlan_id       = each.value.network_device_vlan_id
  ip_config                    = each.value.ip_config
  description                  = each.value.description
  tags                         = each.value.tags
  node_name                    = each.value.node_name
  cloud_image_id               = proxmox_virtual_environment_download_file.cloud_image.id
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

resource "ansible_host" "vms" {
  for_each = module.vm

  name   = each.key
  groups = try(local.vm_configs[each.key].ansible_groups, local.common_config.ansible_groups)
  variables = {
    ansible_host               = each.value.vm_ipv4_addresses[1][0]
    ansible_python_interpreter = "/usr/bin/python3"
  }
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

resource "pihole_dns_record" "vm_dns_ipv4" {
  for_each = module.vm

  domain = coalesce(local.vm_configs[each.key].fqdn, "${each.key}.${local.common_config.dns_domain}")
  ip     = each.value.vm_ipv4_addresses[1][0]
}
