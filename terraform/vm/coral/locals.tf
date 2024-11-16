# define a local variable for common configurations
locals {
  vm_id_start = 134
  # define VMs
  vms = {
    coral = {
      ansible_groups   = ["prod", "docker"]
      tags             = ["prod", "coral"]
      cpu_cores        = 2
      disk_size        = 25
      memory_dedicated = 4096
    }
  }
  common_config = {
    description                    = "Managed by Terraform"
    tags                           = ["debian", "terraform", "controlplane", "etcd", "jonbox"]
    ansible_groups                 = ["debian", "terraform", "controlplane", "etcd", "jonbox"]
    node_name                      = "lich"
    datastore_id                   = "local-lvm"
    cloud_image_node_name          = "lich"
    cloud_image_datastore_id       = "local"
    dns_domain                     = "internal"
    reboot                         = false
    cloud_image_url                = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
    cloud_image_file_name          = "debian-12-generic-coral.img"
    cloud_image_checksum           = ""
    cloud_image_checksum_algorithm = "sha512"
    cloud_image_content_type       = "iso"
    cloud_image_packages           = ["qemu-guest-agent", "python3.11"]
    virtual_environment_endpoint   = var.virtual_environment_endpoint
    virtual_environment_password   = var.virtual_environment_password
    virtual_environment_username   = var.virtual_environment_username
    tpm_state_datastore_id         = "local"
    memory_dedicated               = 4096
    cpu_cores                      = 4
    disk_size                      = 10
    network_device_vlan_id         = 131
    ip_config = {
      ipv4_address = "dhcp"
      ipv4_gateway = ""
      ipv6_address = ""
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
