resource "proxmox_virtual_environment_vm" "ubuntu_template" {
  name        = "ubuntu-template"
  node_name   = "lich"
  description = "Managed by Terraform"

  initialization {
    datastore_id = "hydra"
    user_account {
      keys     = var.sshkeys
      username = var.vm_username
      password = var.vm_password
    }

    dns {
      domain  = "local"
      servers = ["10.30.0.1", "1.1.1.1"]
    }

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  disk {
    datastore_id = "hydra"
    file_id      = proxmox_virtual_environment_file.ubuntu_cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 20
  }

  network_device {
    vlan_id = 30
  }

  tpm_state {
    version = "v2.0"
  }

  template = true
  reboot   = true
}

resource "proxmox_virtual_environment_vm" "sentinel-01" {
  name                = "sentinel-01"
  node_name           = "lich"
  description         = "Managed by Terraform"
  vm_id               = 20001

  clone {
    vm_id = proxmox_virtual_environment_vm.ubuntu_template.id
  }

  memory {
    dedicated = 2048
  }

  cpu {
    cores = 2
  }

  initialization {
    ip_config {
      ipv4 {
        address = "10.30.0.11/24"
        gateway = "10.30.0.1"
      }
    }
  }
}

resource "proxmox_virtual_environment_vm" "cavalier-01" {
  name        = "cavalier-01"
  node_name   = "lich"
  description = "Managed by Terraform"
  vm_id       = 20101

  clone {
    vm_id = proxmox_virtual_environment_vm.ubuntu_template.id
  }

  memory {
    dedicated = 8192
  }

  cpu {
    cores = 2
  }

  initialization {
    ip_config {
      ipv4 {
        address = "10.30.0.101/24"
        gateway = "10.30.0.1"
      }
    }
  }
}

resource "proxmox_virtual_environment_file" "ubuntu_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "lich"

  source_file {
    # you may download this image locally on your workstation and then use the local path instead of the remote URL
    path      = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
    file_name = "ubuntu-22.04.img"

    # you may also use the SHA256 checksum of the image to verify its integrity
    # checksum = "a370d8e6141e5359ca865c29cc8b6d95926b0c162e906453e388ccf24d353b6b"
  }
}
