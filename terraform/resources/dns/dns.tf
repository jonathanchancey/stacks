terraform {
  required_providers {
    dns = {
      source = "hashicorp/dns"
      version = "3.4.0"
    }
  }
}

provider "dns" {
  # Configuration options
  update {
    server        = "10.10.0.3"
    key_name      = "example.com."
    key_algorithm = "hmac-md5"
    key_secret    = ""
  }
}
