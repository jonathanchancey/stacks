# define a local variable for common configurations
locals {
  vm_id_start = 25100
  # define VMs
  vms = {
    node-00 = {}
    node-01 = {}
    another-node-00 = {
      tags = ["talos", "terraform", "worker"]
    }
  }
  common_config = {
    description                    = "Managed by Terraform"
    tags                           = ["talos", "terraform", "controlplane"]
    node_name                      = "TARS"
    cloud_image_node_name          = "TARS"
    datastore_id                   = "cornfield"
    cloud_image_datastore_id       = "local"
    dns_domain                     = "internal"
    reboot                         = false
    cloud_image_url                = "https://factory.talos.dev/image/376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba/v1.7.6/nocloud-amd64.iso"
    cloud_image_file_name          = "talos-nocloud-amd64.iso"
    cloud_image_checksum           = null
    cloud_image_checksum_algorithm = null
    cloud_image_content_type       = "iso"
    tpm_state_datastore_id         = "local"
    memory_dedicated               = 4096
    cpu_cores                      = 4
    disk_size                      = 12
    network_device_vlan_id         = 131
    # set dynamically
    fqdn  = null
    vm_id = null
    # hypervisor auth
    virtual_environment_endpoint = var.virtual_environment_endpoint
    virtual_environment_password = var.virtual_environment_password
    virtual_environment_username = var.virtual_environment_username
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
