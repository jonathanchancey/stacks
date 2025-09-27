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
      version = "0.84.0"
    }
    ansible = {
      source  = "ansible/ansible"
      version = "1.3.0"
    }
    pihole = {
      source  = "ryanwholey/pihole"
      version = "0.2.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
}

provider "pihole" {
  url = "https://pit.fkn.chancey.dev/"

  # Requires Pi-hole Web Interface >= 5.11.0
  api_token = var.pihole_api_token
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "proxmox" {
  endpoint = var.virtual_environment_endpoint
  username = var.virtual_environment_username
  password = var.virtual_environment_password
  insecure = true
  ssh {
    agent = true
  }
}
