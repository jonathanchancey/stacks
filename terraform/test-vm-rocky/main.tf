resource "proxmox_virtual_environment_vm" "centos_vm" {
  name      = "test-rocky"
  node_name = "lich"

  initialization {
    datastore_id = "hydra"
    user_account {
      # do not use this in production, configure your own ssh key instead!
      username = var.vm_username
      password = var.vm_password
    }
  }

  disk {
    datastore_id = "hydra"
    file_id      = proxmox_virtual_environment_file.centos_cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 10
  }
}

resource "proxmox_virtual_environment_file" "centos_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "lich"

  source_file {
    # you may download this image locally on your workstation and then use the local path instead of the remote URL
    path      = "https://dl.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2"
    file_name = "rocky9.img"

    # you may also use the SHA256 checksum of the image to verify its integrity
    checksum = "7713278c37f29b0341b0a841ca3ec5c3724df86b4d97e7ee4a2a85def9b2e651"
  }
}