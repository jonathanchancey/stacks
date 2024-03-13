resource "proxmox_virtual_environment_vm" "sentinel_00" {
  name        = "sentinel-00"
  node_name   = "forest"
  description = "Managed by Terraform"
  tags        = ["terraform", "opensuse"]
  vm_id       = 25000

  memory {
    dedicated = 4096
  }

  cpu {
    cores = 2
  }

  disk {
    datastore_id = "foxes-dir"
    file_id      = proxmox_virtual_environment_file.opensuse_cloud_image_sentinel_00.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 26
  }

  initialization {
    user_account {
      keys     = var.sshkeys
      username = var.vm_server_username
      password = var.vm_server_password
    }
    dns {
      domain  = "local"
      servers = ["10.30.0.1", "1.1.1.1"]
    }
    ip_config {
      ipv4 {
        address = "10.30.0.10/24"
        gateway = "10.30.0.1"
      }
    }
  }
}

resource "proxmox_virtual_environment_file" "opensuse_cloud_image_sentinel_00" {
  content_type = "iso"
  datastore_id = "foxes-dir"
  node_name    = "forest"

  source_file {
    # you may download this image locally on your workstation and then use the local path instead of the remote URL
    path      = "https://download.opensuse.org/distribution/leap/15.5/appliances/openSUSE-Leap-15.5-Minimal-VM.x86_64-Cloud.qcow2"
    file_name = "openSUSE-Leap-15.5.img"

    # you may also use the SHA256 checksum of the image to verify its integrity
    checksum = "a356e5f259156b426cb54b280602fa424e10660167863a1fe9b8776fded4946a"
  }
}
