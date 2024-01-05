module "sentinel-00" {
  source                   = "../../modules/proxmox-qemu" # Adjust the path as needed
  name                     = "sentinel-00"
  target_node              = "forest"
  vmid                     = 20000
  sshkeys                  = var.sshkeys
  nameserver               = var.nameserver
  proxmox_api_url          = var.proxmox_api_url
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret
}

module "sentinel-01" {
  source                   = "../../modules/proxmox-qemu" # Adjust the path as needed
  name                     = "sentinel-01"
  target_node              = "lich"
  vmid                     = 20001
  sshkeys                  = var.sshkeys
  nameserver               = var.nameserver
  proxmox_api_url          = var.proxmox_api_url
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret
}

module "sentinel-02" {
  source                   = "../../modules/proxmox-qemu" # Adjust the path as needed
  name                     = "sentinel-02"
  target_node              = "okapi"
  vmid                     = 20002
  sshkeys                  = var.sshkeys
  nameserver               = var.nameserver
  proxmox_api_url          = var.proxmox_api_url
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret
}

module "cavalier-00" {
  source                   = "../../modules/proxmox-qemu" # Adjust the path as needed
  name                     = "cavalier-00"
  target_node              = "forest"
  vmid                     = 20100
  memory                   = 8192
  nameserver               = var.nameserver
  sshkeys                  = var.sshkeys
  proxmox_api_url          = var.proxmox_api_url
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret
}

module "cavalier-01" {
  source                   = "../../modules/proxmox-qemu" # Adjust the path as needed
  name                     = "cavalier-01"
  target_node              = "lich"
  vmid                     = 20101
  memory                   = 8192
  nameserver               = var.nameserver
  sshkeys                  = var.sshkeys
  proxmox_api_url          = var.proxmox_api_url
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret
}
