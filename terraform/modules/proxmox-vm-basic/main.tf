resource "proxmox_virtual_environment_vm" "vm" {
  name        = var.name
  node_name   = var.node_name
  description = var.description
  tags        = var.tags
  vm_id       = var.vm_id

  network_device {
    vlan_id = var.network_device_vlan_id
  }

  disk {
    datastore_id = var.datastore_id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = var.disk_size
    file_format  = "raw"
  }

  cdrom {
    enabled = true
    file_id = "local:iso/talos-nocloud-amd64.iso"
  }

  dynamic "hostpci" {
    for_each = var.hostpci != null ? [var.hostpci] : []
    content {
      device = hostpci.value.device
      id     = hostpci.value.id
      pcie   = hostpci.value.pcie
      rombar = hostpci.value.rombar
      xvga   = hostpci.value.xvga
    }
  }

  # Dynamic block for optional additional disk
  dynamic "disk" {
    for_each = var.additional_disk_size > 0 ? [1] : []
    content {
      datastore_id = var.additional_disk_datastore_id
      file_format  = var.additional_disk_file_format
      interface    = "virtio1"
      iothread     = true
      discard      = "on"
      size         = var.additional_disk_size
    }
  }

  tpm_state {
    datastore_id = var.tpm_state_datastore_id
    version      = var.tpm_state
  }

  dynamic "clone" {
    for_each = var.clone
    content {
      vm_id = var.clone_vm_id
    }
  }

  memory {
    dedicated = var.memory_dedicated
  }
  vga {
    type = "std"
  }

  cpu {
    cores = var.cpu_cores
    type  = "x86-64-v2-AES"
  }

  template = var.template
  reboot   = var.reboot

}
