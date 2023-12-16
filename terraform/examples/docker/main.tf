module "acolyte-00" {
  source                   = "../../modules/proxmox-qemu"
  name                     = "acolyte-00"
  target_node              = "okapi"
  vmid                     = 16000
  sshkeys                  = var.sshkeys
  proxmox_api_url          = var.proxmox_api_url
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret
}


module "neophyte-00" {
  source                   = "../../modules/proxmox-qemu"
  name                     = "neophyte-00"
  target_node              = "okapi"
  vmid                     = 16001
  memory                   = 8196
  sshkeys                  = var.sshkeys
  proxmox_api_url          = var.proxmox_api_url
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret
}
