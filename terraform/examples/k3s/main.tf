
# module "proxmox" {
#   source       = "../../modules/proxmox-qemu"
#   pm_api_url          = var.proxmox_api_url
#   pm_api_token_id     = var.proxmox_api_token_id
#   pm_api_token_secret = var.proxmox_api_token_secret
# }

# module "vm1" {
#   source       = "../../modules/proxmox-qemu"
#   full_clone  = true
#   scsihw      = "virtio-scsi-pci"
#   onboot      = true
#   cpu         = "host"
#   os_type     = "cloud-init"
# }

module "proxmox_vm_example1" {
  source              = "../../modules/proxmox-qemu" # Adjust the path as needed
  vmid                = 0
  memory              = 2048
  agent               = 0
  sshkeys             = var.sshkeys
  name                = "acolyte-00"
  target_node         = "shar"
  proxmox_api_url     = var.proxmox_api_url
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret
}