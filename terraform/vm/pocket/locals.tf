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

# merge common config and vms
#   vm_configs = {
#     for name in local.vm_names : name => merge(
#       local.common_config,
#       local.vms[name],
#       {
#         vm_id = local.vm_id_start + index(local.vm_names, name)
#       }
#     )
#   }
# Merge common_config with each VM's specific config
#   vm_configs = {
#     for name, vm in local.vms : name => merge(local.common_config, vm)
#   }

