


module "template-00" {
  source                       = "../../modules/proxmox-vm"
  name                         = "rke-template"
  node_name                    = "forest"
  cloud_image_node_name        = "forest"
  template                     = true
  sshkeys                      = var.sshkeys
  username                     = var.username
  password                     = var.password
  virtual_environment_endpoint = var.virtual_environment_endpoint
  virtual_environment_password = var.virtual_environment_password
  virtual_environment_username = var.virtual_environment_username
}


# module "sentinel-00" {
#   source                   = "../../modules/proxmox-vm" # Adjust the path as needed
#   name                     = "sentinel-00"
#   target_node              = "forest"
#   vmid                     = 20000
#   sshkeys                  = var.sshkeys
#   nameserver               = var.nameserver
#   proxmox_api_url          = var.proxmox_api_url
#   proxmox_api_token_id     = var.proxmox_api_token_id
#   proxmox_api_token_secret = var.proxmox_api_token_secret
# }

# module "sentinel-01" {
#   source                   = "../../modules/proxmox-qemu" # Adjust the path as needed
#   name                     = "sentinel-01"
#   target_node              = "lich"
#   vmid                     = 20001
#   sshkeys                  = var.sshkeys
#   nameserver               = var.nameserver
#   proxmox_api_url          = var.proxmox_api_url
#   proxmox_api_token_id     = var.proxmox_api_token_id
#   proxmox_api_token_secret = var.proxmox_api_token_secret
# }

# module "sentinel-02" {
#   source                   = "../../modules/proxmox-qemu" # Adjust the path as needed
#   name                     = "sentinel-02"
#   target_node              = "okapi"
#   vmid                     = 20002
#   sshkeys                  = var.sshkeys
#   nameserver               = var.nameserver
#   proxmox_api_url          = var.proxmox_api_url
#   proxmox_api_token_id     = var.proxmox_api_token_id
#   proxmox_api_token_secret = var.proxmox_api_token_secret
# }

# module "cavalier-00" {
#   source                   = "../../modules/proxmox-qemu" # Adjust the path as needed
#   name                     = "cavalier-00"
#   target_node              = "forest"
#   vmid                     = 20100
#   memory                   = 8192
#   nameserver               = var.nameserver
#   sshkeys                  = var.sshkeys
#   proxmox_api_url          = var.proxmox_api_url
#   proxmox_api_token_id     = var.proxmox_api_token_id
#   proxmox_api_token_secret = var.proxmox_api_token_secret
# }

# module "cavalier-01" {
#   source                   = "../../modules/proxmox-qemu" # Adjust the path as needed
#   name                     = "cavalier-01"
#   target_node              = "lich"
#   vmid                     = 20101
#   memory                   = 8192
#   nameserver               = var.nameserver
#   sshkeys                  = var.sshkeys
#   proxmox_api_url          = var.proxmox_api_url
#   proxmox_api_token_id     = var.proxmox_api_token_id
#   proxmox_api_token_secret = var.proxmox_api_token_secret
# }
