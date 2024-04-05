module "maia" {
  source                       = "../modules/proxmox-vm"
  name                         = "maia"
  description                  = "Managed by Terraform"
  tags                         = ["opensuse", "terraform"]
  node_name                    = "super-earth"
  cloud_image_node_name        = "super-earth"
  datastore_id                 = "local"
  cloud_image_datastore_id     = "local"
  vm_id                        = 2184
  memory_dedicated             = 32768
  cpu_cores                    = 32
  disk_size                    = 30
  dns_domain                   = "local"
  dns_servers                  = ["10.10.0.1", "1.1.1.1"]
  ip_config_gateway            = "10.10.0.1"
  ip_config_ipv4               = "10.10.0.29/24"
#   vlan
  sshkeys                      = var.sshkeys
  username                     = var.username
  password                     = var.password
  reboot                       = false
  cloud_image_url              = "https://download.opensuse.org/distribution/leap/15.5/appliances/openSUSE-Leap-15.5-Minimal-VM.x86_64-Cloud.qcow2"
  cloud_image_file_name        = "openSUSE-Leap-15.5.img"
  cloud_image_checksum         = "a356e5f259156b426cb54b280602fa424e10660167863a1fe9b8776fded4946a"
  virtual_environment_endpoint = var.virtual_environment_endpoint
  virtual_environment_password = var.virtual_environment_password
  virtual_environment_username = var.virtual_environment_username
  tpm_state_datastore_id = "local"
}