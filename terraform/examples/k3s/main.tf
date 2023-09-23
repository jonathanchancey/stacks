module "acolyte-00" {
  source                   = "../../modules/proxmox-qemu" # Adjust the path as needed
  name                     = "acolyte-00"
  target_node              = "shar"
  sshkeys                  = var.sshkeys
  proxmox_api_url          = var.proxmox_api_url
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret
}

module "acolyte-01" {
  source                   = "../../modules/proxmox-qemu" # Adjust the path as needed
  name                     = "acolyte-01"
  target_node              = "selune"
  sshkeys                  = var.sshkeys
  proxmox_api_url          = var.proxmox_api_url
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret
}

module "acolyte-02" {
  source                   = "../../modules/proxmox-qemu" # Adjust the path as needed
  name                     = "acolyte-02"
  target_node              = "okapi"
  sshkeys                  = var.sshkeys
  proxmox_api_url          = var.proxmox_api_url
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret
}

module "neophyte-00" {
  source                   = "../../modules/proxmox-qemu" # Adjust the path as needed
  name                     = "neophyte-00"
  target_node              = "shar"
  sshkeys                  = var.sshkeys
  proxmox_api_url          = var.proxmox_api_url
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret
}

module "neophyte-01" {
  source                   = "../../modules/proxmox-qemu" # Adjust the path as needed
  name                     = "neophyte-01"
  target_node              = "selune"
  sshkeys                  = var.sshkeys
  proxmox_api_url          = var.proxmox_api_url
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret
}

module "neophyte-02" {
  source                   = "../../modules/proxmox-qemu" # Adjust the path as needed
  name                     = "neophyte-02"
  target_node              = "okapi"
  sshkeys                  = var.sshkeys
  proxmox_api_url          = var.proxmox_api_url
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret
}