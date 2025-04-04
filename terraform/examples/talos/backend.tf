terraform {
  backend "s3" {
    bucket                      = "unique-bucket-name"
    key                         = "path/to/terraform.tfstate"
    region                      = "us-east-005"
    endpoint                    = "https://s3.us-east-005.backblazeb2.com"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
    force_path_style            = true
  }
}
