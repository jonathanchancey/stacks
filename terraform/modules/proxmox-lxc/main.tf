terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.14"
    }
    # ansible = {
    #   # version = "~> 1.0.0"
    #   source  = "ansible/ansible"
    # }
  }
}

provider "proxmox" {
  pm_api_url    = var.proxmox_api_url
  pm_user       = var.proxmox_user
  pm_password   = var.proxmox_password
  pm_debug      = true
  pm_log_enable = true
  pm_log_file   = "terraform-plugin-proxmox.log"
  pm_log_levels = {
    _default    = "debug"
    _capturelog = ""
  }
}

resource "proxmox_lxc" "template_lxc" {
  target_node     = var.target_node
  hostname        = var.hostname
  description     = var.description
  ostemplate      = var.ostemplate
  password        = var.password
  unprivileged   = var.unprivileged
  cores           = var.cores
  memory          = var.memory
  onboot          = var.onboot
  ssh_public_keys = var.ssh_public_keys

  features {
    fuse    = var.features_fuse
    nesting = var.features_nesting
    mount   = var.features_mount
  }

  rootfs {
    storage = var.rootfs_storage
    size    = var.rootfs_size
  }

  network {
    name   = var.network_name
    bridge = var.network_bridge
    ip     = var.network_ip
  }

}
