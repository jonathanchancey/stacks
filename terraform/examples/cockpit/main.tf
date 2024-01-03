module "oak" {
  source           = "../../modules/proxmox-lxc"
  hostname         = "oak"
  target_node      = "forest"
  ssh_public_keys  = var.ssh_public_keys
  proxmox_api_url  = var.proxmox_api_url
  proxmox_user     = var.proxmox_user
  proxmox_password = var.proxmox_password
  description      = "smb shares"
  ostemplate       = "foxes-dir:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst"
  password         = var.password
  unprivileged     = false
  cores            = 2
  memory           = 2048
  onboot           = true
  features_fuse    = true
  features_mount   = "nfs;cifs"
  rootfs_storage   = "foxes"
  rootfs_size      = "12G"
}
