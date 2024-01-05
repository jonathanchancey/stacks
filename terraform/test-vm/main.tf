resource "proxmox_virtual_environment_vm" "centos_vm" {
  name      = "test-centos"
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
    size         = 20
  }
}

resource "proxmox_virtual_environment_file" "centos_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "lich"

  source_file {
    # you may download this image locally on your workstation and then use the local path instead of the remote URL
    path      = "https://cloud.centos.org/centos/8-stream/x86_64/images/CentOS-Stream-GenericCloud-8-20231113.0.x86_64.qcow2"
    file_name = "centos8.img"

    # you may also use the SHA256 checksum of the image to verify its integrity
    checksum = "ea8a1d82f6ba09cb631fe9df7abea13ab1563073dcb38cb0005a94ac490dacd0"
  }
}