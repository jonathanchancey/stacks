terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.5.3"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.1.0"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.85.1"
    }
    ansible = {
      source  = "ansible/ansible"
      version = "1.3.0"
    }
  }
}
