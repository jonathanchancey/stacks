module "watch-00" {
  source                   = "../../modules/proxmox-qemu" # Adjust the path as needed
  name                     = "watch-00"
  target_node              = "okapi"
  vmid                     = 2100
  memory                   = 4096
  nameserver               = var.nameserver
  sshkeys                  = var.sshkeys
  proxmox_api_url          = var.proxmox_api_url
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret
  network_tag = 30
}
