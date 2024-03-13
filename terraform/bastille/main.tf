module "forest-sentinel" {
  source                       = "../modules/proxmox-vm"
  name                         = "forest-sentinel"
  description                  = "Managed by Terraform"
  tags                         = ["opensuse", "terraform"]
  node_name                    = "forest"
  cloud_image_node_name        = "forest"
  datastore_id                 = "foxes-dir"
  cloud_image_datastore_id     = "foxes-dir"
  vm_id                        = 25000
  memory_dedicated             = 4096
  cpu_cores                    = 2
  disk_size                    = 26
  dns_domain                   = "local"
  dns_servers                  = ["10.30.0.1", "1.1.1.1"]
  ip_config_gateway            = "10.30.0.1"
  ip_config_ipv4               = "10.30.0.10/24"
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
  additional_disk_datastore_id = "ferris"
  additional_disk_size         = 50
  additional_disk_file_format = "raw"
}

module "lich-sentinel" {
  source                       = "../modules/proxmox-vm"
  name                         = "lich-sentinel"
  description                  = "Managed by Terraform"
  tags                         = ["opensuse", "terraform"]
  node_name                    = "lich"
  cloud_image_node_name        = "lich"
  datastore_id                 = "local-lvm"
  cloud_image_datastore_id     = "local"
  vm_id                        = 25001
  memory_dedicated             = 4096
  cpu_cores                    = 2
  disk_size                    = 26
  dns_domain                   = "local"
  dns_servers                  = ["10.30.0.1", "1.1.1.1"]
  ip_config_gateway            = "10.30.0.1"
  ip_config_ipv4               = "10.30.0.11/24"
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
}

module "selune-sentinel" {
  source                       = "../modules/proxmox-vm"
  name                         = "selune-sentinel"
  description                  = "Managed by Terraform"
  tags                         = ["opensuse", "terraform"]
  node_name                    = "selune"
  cloud_image_node_name        = "selune"
  datastore_id                 = "local-lvm"
  cloud_image_datastore_id     = "local"
  vm_id                        = 25002
  memory_dedicated             = 4096
  cpu_cores                    = 2
  disk_size                    = 26
  dns_domain                   = "local"
  dns_servers                  = ["10.30.0.1", "1.1.1.1"]
  ip_config_gateway            = "10.30.0.1"
  ip_config_ipv4               = "10.30.0.12/24"
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
}

module "lich-cavalier" {
  source                       = "../modules/proxmox-vm"
  name                         = "lich-cavalier"
  description                  = "Managed by Terraform"
  tags                         = ["opensuse", "terraform"]
  node_name                    = "lich"
  cloud_image_node_name        = "lich"
  datastore_id                 = "local-lvm"
  cloud_image_datastore_id     = "local"
  vm_id                        = 25100
  memory_dedicated             = 8192
  cpu_cores                    = 8
  disk_size                    = 30
  dns_domain                   = "local"
  dns_servers                  = ["10.30.0.1", "1.1.1.1"]
  ip_config_gateway            = "10.30.0.1"
  ip_config_ipv4               = "10.30.0.100/24"
  sshkeys                      = var.sshkeys
  username                     = var.username
  password                     = var.password
  reboot                       = false
  cloud_image_url              = "https://download.opensuse.org/distribution/leap/15.5/appliances/openSUSE-Leap-15.5-Minimal-VM.x86_64-Cloud.qcow2"
  cloud_image_file_name        = "openSUSE-Leap-15.5-2.img"
  cloud_image_checksum         = "a356e5f259156b426cb54b280602fa424e10660167863a1fe9b8776fded4946a"
  virtual_environment_endpoint = var.virtual_environment_endpoint
  virtual_environment_password = var.virtual_environment_password
  virtual_environment_username = var.virtual_environment_username
}

module "okapi-cavalier" {
  source                       = "../modules/proxmox-vm"
  name                         = "okapi-cavalier"
  description                  = "Managed by Terraform"
  tags                         = ["opensuse", "terraform"]
  node_name                    = "okapi"
  cloud_image_node_name        = "okapi"
  datastore_id                 = "local-lvm"
  cloud_image_datastore_id     = "local"
  vm_id                        = 25101
  memory_dedicated             = 8192
  cpu_cores                    = 8
  disk_size                    = 30
  dns_domain                   = "local"
  dns_servers                  = ["10.30.0.1", "1.1.1.1"]
  ip_config_gateway            = "10.30.0.1"
  ip_config_ipv4               = "10.30.0.101/24"
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
}