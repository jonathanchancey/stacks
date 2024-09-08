# define a local variable for common configurations
locals {
  vm_id_start = 114
  # define VMs
  vms = {
    blobfish = {
      ansible_groups = ["debian", "production"]
    }
  }
  common_config = {
    description                    = "Managed by Terraform"
    tags                           = ["debian", "terraform"]
    ansible_groups                 = ["debian", "docker"]
    node_name                      = "okapi"
    cloud_image_node_name          = "okapi"
    datastore_id                   = "vm"
    cloud_image_datastore_id       = "local"
    dns_domain                     = "internal"
    reboot                         = false
    cloud_image_url                = "https://cloud.debian.org/images/cloud/bookworm/20240901-1857/debian-12-generic-amd64-20240901-1857.qcow2"
    cloud_image_file_name          = "debian-12-generic-amd64-20240901-1857-blobfish.img"
    cloud_image_checksum           = "58a8c91bcaf4e60e32e8153577726a5a68d55def99566b6e5c343b12ba51c24b98b1bc227e59a39f2750a512107d9ca73e59bfc2ed649600fb62098803615942"
    cloud_image_checksum_algorithm = "sha512"
    cloud_image_content_type       = "iso"
    virtual_environment_endpoint   = var.virtual_environment_endpoint
    virtual_environment_password   = var.virtual_environment_password
    virtual_environment_username   = var.virtual_environment_username
    tpm_state_datastore_id         = "local"
    memory_dedicated               = 4096
    cpu_cores                      = 4
    disk_size                      = 250
    network_device_vlan_id         = 131
    ip_config = {
      ipv4_address = "dhcp"
      ipv4_gateway = ""
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
