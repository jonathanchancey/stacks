resource "proxmox_virtual_environment_vm" "vm" {
  name        = var.name
  node_name   = var.node_name
  description = var.description
  tags        = var.tags
  vm_id       = var.vm_id

  agent {
    enabled = var.agent
  }

  initialization {
    datastore_id = var.datastore_id

    user_data_file_id = proxmox_virtual_environment_file.cloud_config.id

    dns {
      domain  = var.dns_domain
      servers = var.dns_servers
    }

    dynamic "ip_config" {
      for_each = var.ip_config != null ? [var.ip_config] : []
      content {
        dynamic "ipv4" {
          for_each = var.ip_config.ipv4_address != null && var.ip_config.ipv4_gateway != null ? [var.ip_config] : []
          content {
            address = var.ip_config.ipv4_address
            gateway = var.ip_config.ipv4_gateway
          }
        }
        dynamic "ipv6" {
          for_each = var.ip_config.ipv6_address != null && var.ip_config.ipv6_gateway != null ? [var.ip_config] : []
          content {
            address = var.ip_config.ipv6_address
            gateway = var.ip_config.ipv6_gateway
          }
        }
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

  # Dynamic block for optional additional disk
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

  tpm_state {
    datastore_id = var.tpm_state_datastore_id
    version      = var.tpm_state
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

  lifecycle {
    ignore_changes = [
      disk[0].file_format,
      disk[0].path_in_datastore,
      initialization[0].user_data_file_id,
    ]
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
    checksum = var.cloud_image_checksum
  }
}

resource "proxmox_virtual_environment_file" "cloud_config" {
  content_type = "snippets"
  datastore_id = var.cloud_image_datastore_id
  node_name    = var.cloud_image_node_name

  source_raw {
    data = <<-EOF
    #cloud-config
    chpasswd:
      list: |
        ${var.username}:${var.password}
      expire: false
    hostname: ${var.name}
    fqdn: ${var.fqdn}
    ssh_pwauth: ${var.cloud_image_ssh_pwauth}
    package_upgrade: true
    manage_etc_hosts: ${var.cloud_image_manage_etc_hosts}
    packages:
      - qemu-guest-agent
    runcmd:
      - timedatectl set-timezone UTC
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
      - echo "done" > /tmp/cloud-config.done
    users:
      - default
      - name: ${var.username}
        groups: sudo
        shell: /bin/bash
        ssh-authorized-keys:
          %{for key in var.sshkeys}
          - ${key}
          %{endfor}
        sudo: ALL=(ALL) NOPASSWD:ALL
      - name: ansible
        groups: users,admin,wheel
        shell: /bin/bash
        sudo: ALL=(ALL) NOPASSWD:ALL
        lock_passwd: true
        ssh_authorized_keys:
          %{for key in var.sshkeys}
          - ${key}
          %{endfor}
    EOF

    file_name = "cloud-config-${var.vm_id}.yaml"
  }
}
