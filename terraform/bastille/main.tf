resource "proxmox_virtual_environment_vm" "microos_template" {
  name        = "MicroOS-template"
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
    file_id      = proxmox_virtual_environment_file.microos_cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 24
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
  hook_script_file_id = proxmox_virtual_environment_file.hook_script_server.id

  clone {
    vm_id = proxmox_virtual_environment_vm.microos_template.id
  }

  memory {
    dedicated = 2048
  }

  cpu {
    cores = 2
  }

}

resource "proxmox_virtual_environment_vm" "cavalier-01" {
  name        = "cavalier-01"
  node_name   = "lich"
  description = "Managed by Terraform"
  hook_script_file_id = proxmox_virtual_environment_file.hook_script_server.id

  clone {
    vm_id = proxmox_virtual_environment_vm.microos_template.id
  }

  memory {
    dedicated = 8192
  }

  cpu {
    cores = 2
  }

}

resource "proxmox_virtual_environment_file" "microos_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "lich"

  source_file {
    # you may download this image locally on your workstation and then use the local path instead of the remote URL
    path      = "https://download.opensuse.org/tumbleweed/appliances/openSUSE-MicroOS.x86_64-16.0.0-ContainerHost-OpenStack-Cloud-Snapshot20240104.qcow2"
    file_name = "openSUSE-MicroOS-cloudstack.img"

    # you may also use the SHA256 checksum of the image to verify its integrity
    # checksum = "a370d8e6141e5359ca865c29cc8b6d95926b0c162e906453e388ccf24d353b6b"
  }
}

resource "proxmox_virtual_environment_file" "hook_script_server" {
  content_type = "snippets"
  datastore_id = "chimera"
  node_name    = "lich"

  # file properties not currently implemented 
  # https://github.com/bpg/terraform-provider-proxmox/pull/733

  # make sure file is executable
  # chmod +x /mnt/pve/chimera/snippets/hook_script_server.sh

  # make sure line endings are LF and not CRLF
  # proxmox will throw a pre-start failed: No such file or directory
  source_raw {
    file_name = "hook_script_server.sh"
    data      = <<EOF
#!/bin/bash
cloud-init status --wait
echo first-run-test >> /root/complete.txt
EOF
  }
}
