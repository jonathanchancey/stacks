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
  network_device_vlan_id       = each.value.network_device_vlan_id
  ip_config                    = each.value.ip_config
  description                  = each.value.description
  tags                         = each.value.tags
  node_name                    = each.value.node_name
  cloud_image_node_name        = each.value.cloud_image_node_name
  datastore_id                 = each.value.datastore_id
  cloud_image_datastore_id     = each.value.cloud_image_datastore_id
  dns_domain                   = each.value.dns_domain
  reboot                       = each.value.reboot
  cloud_image_url              = each.value.cloud_image_url
  cloud_image_file_name        = each.value.cloud_image_file_name
  cloud_image_checksum         = each.value.cloud_image_checksum
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
  groups = ["kube_control_plane", "kube_node"]
  variables = {
    ansible_host = each.value.vm_ipv6_addresses[1][0]
  }
}

# resource "ansible_group" "cluster" {
#   name     = "k8s"
#   children = ["kube_control_plane", "kube_node"]
# }

# resource "ansible_host" "debug" {
#   name   = "debian-debug"
#   groups = ["kube_control_plane", "kube_node"]
#   variables = {
#     ansible_host = module.vm["pocket"].vm_ipv6_addresses[1][0]
#   }
# }
