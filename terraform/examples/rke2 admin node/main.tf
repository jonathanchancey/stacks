module "oak" {
  source           = "../../modules/proxmox-lxc"
  hostname         = "pallas"
  target_node      = "forest"
  ssh_public_keys  = var.ssh_public_keys
  proxmox_api_url  = var.proxmox_api_url
  proxmox_user     = var.proxmox_user
  proxmox_password = var.proxmox_password
  description      = "k8s management"
  ostemplate       = "foxes-dir:vztmpl/opensuse-15.5-default_20231118_amd64.tar.xz"
  password         = var.password
  unprivileged     = true
  cores            = 4
  memory           = 4096
  onboot           = false
  rootfs_storage   = "foxes"
  rootfs_size      = "12G"
}
