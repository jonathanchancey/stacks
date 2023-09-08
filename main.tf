terraform {
    required_providers = ">= 0.13"
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "v2.9.14"
    }
  }
}

provider "proxmox" {
  api_url = var.proxmox_api_url
  api_token_id = var.proxmox_api_token_id
  api_token_secret = var.proxmox_api_token_secret
}

variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type = string
  sensitive = true
}

variable "proxmox_api_token_secret" {
  type = string
  sensitive = true
}