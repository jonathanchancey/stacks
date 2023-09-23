module "vm1" {
  source       = "./proxmox-qemu"
  full_clone  = true
  scsihw      = "virtio-scsi-pci"
  onboot      = true
  cpu         = "host"
  os_type     = "cloud-init"
}

  name        = var.name
  desc        = var.desc
  vmid        = var.vmid
  target_node = var.target_node
  agent       = var.agent
  clone       = var.clone_template_name
  cores       = var.cores
  sockets     = var.sockets
  memory      = var.memory
  ipconfig0   = var.ipconfig0
  nameserver  = var.nameserver
  ssh_user    = var.ssh_user
  sshkeys     = var.sshkeys