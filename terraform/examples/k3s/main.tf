

module "proxmox_vm_example1" {
  source                   = "../../modules/proxmox-qemu" # Adjust the path as needed
  sshkeys                  = var.sshkeys
  name                     = "acolyte-00"
  target_node              = "shar"
  proxmox_api_url          = var.proxmox_api_url
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret
}