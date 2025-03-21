module "vm" {
  source = "git::git@github.com:jonathanchancey/stacks.git//terraform/modules/proxmox-vm-cloudconfig?ref=fc07c0d9228ad85a2c20e853d21314d691e04418"

  for_each = local.vm_configs

  # individual configuration
  name                           = each.value.name
  vm_id                          = each.value.vm_id
  memory_dedicated               = each.value.memory_dedicated
  cpu_cores                      = each.value.cpu_cores
  disk_size                      = each.value.disk_size
  fqdn                           = try(each.value.fqdn, null)
  hostpci                        = try(each.value.hostpci, null)
  network_device_vlan_id         = each.value.network_device_vlan_id
  ip_config                      = each.value.ip_config
  description                    = each.value.description
  tags                           = each.value.tags
  node_name                      = each.value.node_name
  cloud_image_node_name          = each.value.cloud_image_node_name
  datastore_id                   = each.value.datastore_id
  cloud_image_datastore_id       = each.value.cloud_image_datastore_id
  dns_domain                     = each.value.dns_domain
  reboot                         = each.value.reboot
  cloud_image_url                = each.value.cloud_image_url
  cloud_image_file_name          = each.value.cloud_image_file_name
  cloud_image_checksum           = each.value.cloud_image_checksum
  cloud_image_checksum_algorithm = each.value.cloud_image_checksum_algorithm
  virtual_environment_endpoint   = each.value.virtual_environment_endpoint
  virtual_environment_password   = each.value.virtual_environment_password
  virtual_environment_username   = each.value.virtual_environment_username
  tpm_state_datastore_id         = each.value.tpm_state_datastore_id

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
    ansible_host = each.value.vm_ipv4_addresses[1][0]
  }
}

resource "pihole_dns_record" "vm_dns_ipv4" {
  for_each = module.vm

  domain = coalesce(local.vm_configs[each.key].fqdn, "${each.key}.${local.common_config.dns_domain}")
  ip     = each.value.vm_ipv4_addresses[1][0]
}
