resource "proxmox_virtual_environment_vm" "vm" {
  name        = var.name
  node_name   = var.node_name
  description = var.description
  tags        = var.tags
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
      ipv6 {
        address = var.ip_config_ipv6_address
        gateway = var.ip_config_ipv6_gateway
      }
    }
  }

  network_device {
    vlan_id = var.network_device_vlan_id
  }

  disk {
    datastore_id = var.datastore_id
    file_id      = proxmox_virtual_environment_file.cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = var.disk_size
  }

  // Dynamic block for optional additional disk
  dynamic "disk" {
    for_each = var.additional_disk_size > 0 ? [1] : []
    content {
      datastore_id = var.additional_disk_datastore_id
      file_format  = var.additional_disk_file_format
      interface    = "virtio1"
      iothread     = true
      discard      = "on"
      size         = var.additional_disk_size
    }
  }

  lifecycle {
    ignore_changes = [
      disk[0].file_format,
      disk[0].path_in_datastore
    ]
  }

  tpm_state {
    datastore_id = var.tpm_state_datastore_id
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

resource "proxmox_virtual_environment_file" "cloud_image" {
  content_type = var.cloud_image_content_type
  datastore_id = var.cloud_image_datastore_id
  node_name    = var.cloud_image_node_name

  source_file {
    # you may download this image locally on your workstation and then use the local path instead of the remote URL
    path      = var.cloud_image_url
    file_name = var.cloud_image_file_name

    # you may also use the SHA256 checksum of the image to verify its integrity
    checksum = var.cloud_image_checksum
  }
}