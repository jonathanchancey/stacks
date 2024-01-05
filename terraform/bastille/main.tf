resource "proxmox_virtual_environment_vm" "microos_vm" {
  name      = "sentinel-01"
  node_name = "lich"
  description = "Managed by Terraform"

  initialization {
    datastore_id = "hydra"
    user_account {
      # do not use this in production, configure your own ssh key instead!
      username = var.vm_username
      password = var.vm_password
    }
    dns {
      servers = ["1.1.1.1"]
    }
    ip_config {
      ipv4 {
        address = "dhcp"
      }
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

  network_device {
    vlan_id = 30
  }

  # connection {
  #   type        = "ssh"
  #   agent       = false
  #   host        = element(element(self.ipv4_addresses, index(self.network_interface_names, "eth0")), 0)
  #   private_key = tls_private_key.example.private_key_pem
  #   user        = "root"
  # }

  # provisioner "remote-exec" {
  #   inline = [
  #     "echo Welcome to $(hostname)!",
  #   ]
  # }
}

resource "proxmox_virtual_environment_file" "microos_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "lich"

  source_file {
    # you may download this image locally on your workstation and then use the local path instead of the remote URL
    path      = "https://download.opensuse.org/tumbleweed/appliances/openSUSE-MicroOS.x86_64-16.0.0-ContainerHost-OpenStack-Cloud-Snapshot20240103.qcow2"
    file_name = "openSUSE-MicroOS-cloudstack.img"

    # you may also use the SHA256 checksum of the image to verify its integrity
    checksum = "a370d8e6141e5359ca865c29cc8b6d95926b0c162e906453e388ccf24d353b6b"
  }
}
