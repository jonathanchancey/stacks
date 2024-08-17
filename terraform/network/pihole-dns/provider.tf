terraform {
  required_providers {
    pihole = {
      source = "ryanwholey/pihole"
      version = "0.2.0"
    }
  }
}

provider "pihole" {
  url = "https://pit.fkn.chancey.dev/"

  # Requires Pi-hole Web Interface >= 5.11.0
  api_token = var.pihole_api_token
}
