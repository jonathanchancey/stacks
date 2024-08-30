# define a local variable for common configurations
locals {
  vm_id_start = 25000
  # define VMs
  vms = {
    convergence-00 = {
      ansible_groups = ["leap", "kube_control_plane", "kube_worker", "coalesce", "initial_server"]
    }
    convergence-01 = {
      ansible_groups = ["leap", "kube_control_plane", "kube_worker", "coalesce"]
    }
    convergence-02 = {
      ansible_groups = ["leap", "kube_control_plane", "kube_worker", "coalesce"]
    }
    divergence-00 = {
      ansible_groups = ["leap", "kube_control_plane", "kube_worker", "dichotomy"]
    }
    divergence-01 = {
      ansible_groups = ["leap", "kube_control_plane", "kube_worker", "dichotomy"]
    }
    divergence-02 = {
      ansible_groups = ["leap", "kube_control_plane", "kube_worker", "dichotomy"]
    }
  }
  common_config = {
    description                    = "Managed by Terraform"
    tags                           = ["leap", "terraform"]
    ansible_groups                 = ["leap", "kube_control_plane", "kube_worker"]
    node_name                      = "TARS"
    cloud_image_node_name          = "TARS"
    datastore_id                   = "cornfield"
    cloud_image_datastore_id       = "local"
    dns_domain                     = "internal"
    reboot                         = false
    cloud_image_url                = "https://download.opensuse.org/distribution/leap/15.6/appliances/openSUSE-Leap-15.6-Minimal-VM.x86_64-Cloud.qcow2"
    cloud_image_file_name          = "openSUSE-Leap-15.6-Minimal-VM.x86_64-Cloud.img"
    cloud_image_checksum           = null
    cloud_image_checksum_algorithm = null
    cloud_image_content_type       = "iso"
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
