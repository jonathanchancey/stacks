resource "proxmox_virtual_environment_vm" "microos_vm" {
  name      = "test-MicroOS"
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
    file_id      = proxmox_virtual_environment_file.microos_cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 10
  }
}

resource "proxmox_virtual_environment_file" "microos_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "lich"

  source_file {
    # you may download this image locally on your workstation and then use the local path instead of the remote URL
    path      = "https://download.opensuse.org/tumbleweed/appliances/openSUSE-MicroOS.x86_64-16.0.0-ContainerHost-kvm-and-xen-Snapshot20240103.qcow2"
    file_name = "openSUSE-MicroOS.img"

    # you may also use the SHA256 checksum of the image to verify its integrity
    checksum = "6ccd5ae51c6511b4f6faccf4ab3c3893a4bf632b185db0cb717739965fb75142"
  }
}