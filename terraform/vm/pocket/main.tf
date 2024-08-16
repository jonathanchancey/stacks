module "pocket" {
  source                   = "../../modules/proxmox-vm-cloudconfig"
  name                     = "pocket"
  description              = "Managed by Terraform"
  tags                     = ["debian", "terraform"]
  node_name                = "TARS"
  cloud_image_node_name    = "TARS"
  datastore_id             = "cornfield"
  cloud_image_datastore_id = "local"
  vm_id                    = 132
  memory_dedicated         = 4096
  cpu_cores                = 4
  disk_size                = 10
  ip_config = {
    ipv6_address = "dhcp"
    ipv6_gateway = ""
  }
  dns_domain                   = ""
  dns_servers                  = var.dns_servers
  sshkeys                      = var.sshkeys
  username                     = var.username
  password                     = var.password
  reboot                       = false
  cloud_image_url              = "https://cloud.debian.org/images/cloud/bookworm/20240717-1811/debian-12-generic-amd64-20240717-1811.qcow2"
  cloud_image_file_name        = "debian-12-generic-amd64-20240717-1811.img"
  cloud_image_checksum         = ""
  virtual_environment_endpoint = var.virtual_environment_endpoint
  virtual_environment_password = var.virtual_environment_password
  virtual_environment_username = var.virtual_environment_username
  tpm_state_datastore_id       = "local"
  network_device_vlan_id       = 131
}
