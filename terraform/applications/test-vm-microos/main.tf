resource "proxmox_virtual_environment_vm" "microos_vm" {
  name      = "test-MicroOS"
  node_name = "lich"

  initialization {
    datastore_id = "hydra"
    user_account {
      # do not use this in production, configure your own ssh key instead!
      username = "root"
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
    # path      = "https://download.opensuse.org/tumbleweed/appliances/openSUSE-MicroOS.x86_64-16.0.0-ContainerHost-kvm-and-xen-Snapshot20240103.qcow2"
    path      = "https://download.opensuse.org/tumbleweed/appliances/openSUSE-MicroOS.x86_64-16.0.0-ContainerHost-OpenStack-Cloud-Snapshot20240103.qcow2"
    file_name = "openSUSE-MicroOS-cloudstack.img"

    # you may also use the SHA256 checksum of the image to verify its integrity
    checksum = "a370d8e6141e5359ca865c29cc8b6d95926b0c162e906453e388ccf24d353b6b"
  }
}