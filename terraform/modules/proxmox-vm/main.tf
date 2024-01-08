resource "proxmox_virtual_environment_vm" "vm_template" {
  name        = var.vm_template_name
  node_name   = var.vm_template_node_name
  description = var.vm_template_description

  initialization {
    datastore_id = var.vm_template_datastore_id
    user_account {
      keys     = var.vm_template_sshkeys
      username = var.vm_template_username
      password = var.vm_template_password
    }

    dns {
      domain  = var.vm_template_dns_domain
      servers = var.vm_template_dns_servers
    }

    ip_config {
      ipv4 {
        address = var.vm_template_ip_config_ipv4
      }
    }
  }

  disk {
    datastore_id = var.vm_template_disk_datastore_id
    file_id      = proxmox_virtual_environment_file.ubuntu_cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 20
  }

  network_device {
    vlan_id = var.vm_template_network_device_vlan_id
  }

  tpm_state {
    version = "v2.0"
  }

  template = true
  reboot   = true
}

resource "proxmox_virtual_environment_vm" "vm_instance" {
  name        = var.vm_instance_name
  node_name   = var.vm_instance_node_name
  description = var.vm_instance_description
  vm_id       = var.vm_instance_vm_id

  clone {
    vm_id = proxmox_virtual_environment_vm.ubuntu_template.id
  }

  memory {
    dedicated = var.vm_instance_memory_dedicated
  }

  cpu {
    cores =var.vm_instance_cpu_cores
  }

  initialization {
    ip_config {
      ipv4 {
        address = var.vm_instance_ip_config_ipv4
        gateway = var.vm_instance_ip_config_gateway
      }
    }
  }
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
    # checksum = "a370d8e6141e5359ca865c29cc8b6d95926b0c162e906453e388ccf24d353b6b"
  }
}
