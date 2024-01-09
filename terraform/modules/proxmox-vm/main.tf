resource "proxmox_virtual_environment_vm" "vm_template" {
  name        = var.name
  node_name   = var.node_name
  description = var.description
  vm_id       = var.vm_id

  initialization {
    datastore_id = var.datastore_id
    user_account {
      username = var.username
      password = var.password
      keys     = var.sshkeys
    }

    dns {
      domain  = var.dns_domain
      servers = var.dns_servers
    }

    ip_config {
      ipv4 {
        address = var.ip_config_ipv4
        gateway = var.ip_config_gateway
      }
    }
  }

  network_device {
    vlan_id = var.network_device_vlan_id
  }

  disk {
    datastore_id = var.disk_datastore_id
    file_id      = proxmox_virtual_environment_file.cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = var.disk_size
  }

  tpm_state {
    version = var.tpm_state
  }

  dynamic "clone" {
    for_each = var.clone
    content { 
      vm_id = var.clone_vm_id
    }
  }

  memory {
    dedicated = var.memory_dedicated
  }

  cpu {
    cores = var.cpu_cores
  }

  template = var.template
  reboot   = var.reboot
}
