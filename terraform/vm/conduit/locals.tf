# define a local variable for common configurations
locals {
  vm_id_start = 15200
  # define VMs
  vms = {
    conduit-00 = {
      ansible_groups = ["debian", "conduit", "db"]
    }
  }

  common_config = {
    description                    = "Managed by Terraform"
    tags                           = ["debian", "terraform"]
    ansible_groups                 = ["debian"]
    node_name                      = "TARS"
    cloud_image_node_name          = "TARS"
    datastore_id                   = "cornfield"
    cloud_image_datastore_id       = "local"
    dns_domain                     = "internal"
    reboot                         = false
    cloud_image_url                = "https://cloud.debian.org/images/cloud/bookworm/20240717-1811/debian-12-generic-amd64-20240717-1811.qcow2"
    cloud_image_file_name          = "debian-12-generic-amd64-20240717-1811.img"
    cloud_image_checksum           = "9ce1ce8c0f16958dd07bce6dd44d12f4d44d12593432a3a8f7c890c262ce78b0402642fa25c22941760b5a84d631cf81e2cb9dc39815be25bf3a2b56388504c6"
    cloud_image_checksum_algorithm = "sha512"
    virtual_environment_endpoint   = var.virtual_environment_endpoint
    virtual_environment_password   = var.virtual_environment_password
    virtual_environment_username   = var.virtual_environment_username
    tpm_state_datastore_id         = "local"
    memory_dedicated               = 4096
    cpu_cores                      = 4
    disk_size                      = 100
    network_device_vlan_id         = 131
    ip_config = {
      ipv4_address = "dhcp"
      ipv4_gateway = ""
      ipv6_address = "dhcp"
      ipv6_gateway = ""
    }
    # set dynamically
    fqdn  = null
    vm_id = null
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
