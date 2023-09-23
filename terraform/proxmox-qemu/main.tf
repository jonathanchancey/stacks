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
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_debug            = true
  pm_log_enable       = true
  pm_log_file         = "terraform-plugin-proxmox.log"
  pm_log_levels = {
    _default    = "debug"
    _capturelog = ""
  }
  #   pm_tls_insecure = true
}

resource "proxmox_vm_qemu" "template_vm" {
  name        = var.name
  desc        = var.desc
  vmid        = var.vmid
  target_node = var.target_node
  agent       = var.agent
  clone       = var.clone_template_name
  full_clone  = true
  cores       = var.cores
  sockets     = var.sockets
  cpu         = "host"
  memory      = var.memory
  scsihw      = "virtio-scsi-pci"
  onboot      = true
  os_type     = "cloud-init"
  ipconfig0   = var.ipconfig0
  nameserver  = var.nameserver
  ssh_user    = var.ssh_user
  sshkeys     = var.sshkeys
}