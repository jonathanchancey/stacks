resource "proxmox_virtual_environment_vm" "ubuntu_template-00" {
  name        = "ubuntu-template"
  node_name   = "forest"
  description = "Managed by Terraform"

  initialization {
    datastore_id = "foxes-dir"
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
    datastore_id = "foxes-dir"
    file_id      = proxmox_virtual_environment_file.ubuntu_cloud_image-00.id
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

resource "proxmox_virtual_environment_vm" "ubuntu_template-01" {
  name        = "ubuntu-template"
  node_name   = "lich"
  description = "Managed by Terraform"

  initialization {
    datastore_id = "local-lvm"
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
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_file.ubuntu_cloud_image-01.id
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

resource "proxmox_virtual_environment_vm" "ubuntu_template-02" {
  name        = "ubuntu-template"
  node_name   = "okapi"
  description = "Managed by Terraform"

  initialization {
    datastore_id = "vm"
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
    datastore_id = "vm"
    file_id      = proxmox_virtual_environment_file.ubuntu_cloud_image-02.id
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

resource "proxmox_virtual_environment_vm" "sentinel-00" {
  name                = "sentinel-00"
  node_name           = "forest"
  description         = "Managed by Terraform"
  vm_id               = 20000

  clone {
    vm_id = proxmox_virtual_environment_vm.ubuntu_template-00.id
  }

  memory {
    dedicated = 4096
  }

  cpu {
    cores = 2
  }

  initialization {
    ip_config {
      ipv4 {
        address = "10.30.0.10/24"
        gateway = "10.30.0.1"
      }
    }
  }
}

resource "proxmox_virtual_environment_vm" "sentinel-01" {
  name                = "sentinel-01"
  node_name           = "lich"
  description         = "Managed by Terraform"
  vm_id               = 20001

  clone {
    vm_id = proxmox_virtual_environment_vm.ubuntu_template-01.id
  }

  memory {
    dedicated = 4096
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

resource "proxmox_virtual_environment_vm" "sentinel-02" {
  name                = "sentinel-02"
  node_name           = "okapi"
  description         = "Managed by Terraform"
  vm_id               = 20002

  clone {
    vm_id = proxmox_virtual_environment_vm.ubuntu_template-02.id
  }

  memory {
    dedicated = 4096
  }

  cpu {
    cores = 2
  }

  initialization {
    ip_config {
      ipv4 {
        address = "10.30.0.12/24"
        gateway = "10.30.0.1"
      }
    }
  }
}

resource "proxmox_virtual_environment_vm" "cavalier-00" {
  name        = "cavalier-00"
  node_name   = "forest"
  description = "Managed by Terraform"
  vm_id       = 20100

  clone {
    vm_id = proxmox_virtual_environment_vm.ubuntu_template-00.id
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
        address = "10.30.0.100/24"
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
    vm_id = proxmox_virtual_environment_vm.ubuntu_template-01.id
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

resource "proxmox_virtual_environment_vm" "cavalier-02" {
  name        = "cavalier-01"
  node_name   = "okapi"
  description = "Managed by Terraform"
  vm_id       = 20102

  clone {
    vm_id = proxmox_virtual_environment_vm.ubuntu_template-02.id
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
        address = "10.30.0.102/24"
        gateway = "10.30.0.1"
      }
    }
  }
}

resource "proxmox_virtual_environment_file" "ubuntu_cloud_image-00" {
  content_type = "iso"
  datastore_id = "foxes-dir"
  node_name    = "forest"

  source_file {
    # you may download this image locally on your workstation and then use the local path instead of the remote URL
    path      = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
    file_name = "ubuntu-22.04-00.img"

    # you may also use the SHA256 checksum of the image to verify its integrity
    # checksum = "a370d8e6141e5359ca865c29cc8b6d95926b0c162e906453e388ccf24d353b6b"
  }
}

resource "proxmox_virtual_environment_file" "ubuntu_cloud_image-01" {
  content_type = "iso"
  datastore_id = "chimera"
  node_name    = "lich"

  source_file {
    # you may download this image locally on your workstation and then use the local path instead of the remote URL
    path      = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
    file_name = "ubuntu-22.04-01.img"

    # you may also use the SHA256 checksum of the image to verify its integrity
    # checksum = "a370d8e6141e5359ca865c29cc8b6d95926b0c162e906453e388ccf24d353b6b"
  }
}


resource "proxmox_virtual_environment_file" "ubuntu_cloud_image-02" {
  content_type = "iso"
  datastore_id = "iso"
  node_name    = "okapi"

  source_file {
    # you may download this image locally on your workstation and then use the local path instead of the remote URL
    path      = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
    file_name = "ubuntu-22.04-02.img"

    # you may also use the SHA256 checksum of the image to verify its integrity
    # checksum = "a370d8e6141e5359ca865c29cc8b6d95926b0c162e906453e388ccf24d353b6b"
  }
}
