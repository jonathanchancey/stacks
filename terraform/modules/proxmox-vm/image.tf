resource "proxmox_virtual_environment_file" "cloud_image" {
  content_type = var.cloud_image_content_type
  datastore_id = var.cloud_image_datastore_id
  node_name    = var.cloud_image_node_name

  source_file {
    # you may download this image locally on your workstation and then use the local path instead of the remote URL
    path      = var.cloud_image_url
    file_name = var.cloud_image_file_name

    # you may also use the SHA256 checksum of the image to verify its integrity
    # checksum = "a370d8e6141e5359ca865c29cc8b6d95926b0c162e906453e388ccf24d353b6b"
  }
}