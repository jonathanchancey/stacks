# define a local variable for common configurations
locals {
  vm_id_start = 2000
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
    memory_dedicated             = 4096
    cpu_cores                    = 4
    disk_size                    = 10
    network_device_vlan_id       = 131
    ip_config = {
      ipv6_address = "dhcp"
      ipv6_gateway = ""
    }
    # fqdn = "pocket.internal"
    # vm_id                        = 132
  }

  # define VMs
  vms = {
    pocket = {
      vm_id = 132
    }
  }
  # create list to sequentially assign ids
  vm_names = keys(local.vms)


  vm_configs = {
    for name in local.vm_names : name => merge(
      local.common_config,
      local.vms[name],
      {
        vm_id = try(
          local.vms[name].vm_id,
          local.vm_id_start + index(local.vm_names, name)
        )
        name = try(local.vms[name].name, name)
      }
    )
  }
}

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
