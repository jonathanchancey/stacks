resource "proxmox_vm_qemu" "acolyte-00" {
  name        = "acolyte-00"
  desc        = "kubernetes"
  vmid        = "1030"
  target_node = "selune"
  agent       = 0

  clone      = "debian-12-cloudinit"
  full_clone = true
  cores      = 4
  sockets    = 1
  cpu        = "host"
  memory     = 2048
  scsihw     = "virtio-scsi-pci"
  onboot     = true

  os_type    = "cloud-init"
  ipconfig0  = "ip=192.168.0.30/24,gw=192.168.0.1"
  nameserver = "192.168.0.3"
  ssh_user   = "kube"
  sshkeys    = <<EOF
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDLV/+WnYhO2RNlMCFqbgajQGGNV/yPesECbO5L1bZBNGHD4p7HaqO0YCmrAV6KcM3hE/n3hUIJ51xBKJppcgqGAhwxnAzb/FqT1h4UjSMa/qeCtypJJMzEddTniCPJJ8khfSeDa/Axu3hli7N12P6svUIdSDBil2kRbAWIZ9jMEX37fD7vu6qC4XI+wpe4kh6+aSO8TrZfAkY32udRp9noPcLbtuEbU+p8lIkTDDrCju3UOCzv4uqVdf47q/UQ9LP1kUcYmx1umR5eP/bthqSEpGC9M8vv50jo+BYL1mR6SOya//jbeYBaES1iDcIZbsx6HXjBX4nvKV/T2Ik/q0M/a8OhEVN4daZGLbyBiChuGidKU9OtXYOud5IBPPECiqZcZ3mnIFQGxuoPziuIopxgwCevbZEcL7rv4fbz0bl5+Y5r05dJhzoSjANsIdoyYXqjRitj87xzH6wPZOdBnHvTIAMxI4quEyPpVtajxZuDr04G6UyuIrKhhyPtm9qlLPU= coal@stone
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDFr6EdUZiVh5LIAZgukLDp93gj/ktEyoNUjcE8QSG3Zovf9VABlxkPY9f7KnQaAB3AeMhEIWYpZbHkMgF2l3TMuhPwp7VABds9lLHdb0YuZYL4Y7peRRhNSF6oDOetOkFt46nTs123aChCfj8UrhIR04PqP//LCBQ/gsS+XEDH4jlYGXCtEfOHgwHNFZPwu9aRA+xTj/5OWxr8e8Qtas8RFxt26Q99iHJRiCQIIckR/mObkvy9+09r04fpcfxCPADA/AvvOBRvdmjD3Pd6WP8GnX8DcAGXsUNYDQPr4dAGh0qV/uHomH16c+bIzygUO1FVEFHfLZUhyvN+UjIVrX+iwlXCs+Juf18a/1mJ/DHK+XpckozGowfBXPD8lvhzU7KCG8BvinZ/UvMUbe5aUsFsCsb60yZ/7Nx9ptcsSN1n0jILm6B7mw3rzWQcmQmErMGq/z7xuqeAklHGc5GuVIVzJ+NzPyiDHjQblxYE0iiTpCv0xdIDnl51/+EDOJhJcjc= seki@yu
    EOF
}

resource "proxmox_vm_qemu" "acolyte-01" {
  name        = "acolyte-01"
  desc        = "kubernetes"
  vmid        = "1031"
  target_node = "selune"
  agent       = 0

  clone      = "debian-12-cloudinit"
  full_clone = true
  cores      = 4
  sockets    = 1
  cpu        = "host"
  memory     = 2048
  scsihw     = "virtio-scsi-pci"
  onboot     = true

  os_type    = "cloud-init"
  ipconfig0  = "ip=192.168.0.31/24,gw=192.168.0.1"
  nameserver = "192.168.0.3"
  ssh_user   = "kube"
  sshkeys    = <<EOF
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDLV/+WnYhO2RNlMCFqbgajQGGNV/yPesECbO5L1bZBNGHD4p7HaqO0YCmrAV6KcM3hE/n3hUIJ51xBKJppcgqGAhwxnAzb/FqT1h4UjSMa/qeCtypJJMzEddTniCPJJ8khfSeDa/Axu3hli7N12P6svUIdSDBil2kRbAWIZ9jMEX37fD7vu6qC4XI+wpe4kh6+aSO8TrZfAkY32udRp9noPcLbtuEbU+p8lIkTDDrCju3UOCzv4uqVdf47q/UQ9LP1kUcYmx1umR5eP/bthqSEpGC9M8vv50jo+BYL1mR6SOya//jbeYBaES1iDcIZbsx6HXjBX4nvKV/T2Ik/q0M/a8OhEVN4daZGLbyBiChuGidKU9OtXYOud5IBPPECiqZcZ3mnIFQGxuoPziuIopxgwCevbZEcL7rv4fbz0bl5+Y5r05dJhzoSjANsIdoyYXqjRitj87xzH6wPZOdBnHvTIAMxI4quEyPpVtajxZuDr04G6UyuIrKhhyPtm9qlLPU= coal@stone
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDFr6EdUZiVh5LIAZgukLDp93gj/ktEyoNUjcE8QSG3Zovf9VABlxkPY9f7KnQaAB3AeMhEIWYpZbHkMgF2l3TMuhPwp7VABds9lLHdb0YuZYL4Y7peRRhNSF6oDOetOkFt46nTs123aChCfj8UrhIR04PqP//LCBQ/gsS+XEDH4jlYGXCtEfOHgwHNFZPwu9aRA+xTj/5OWxr8e8Qtas8RFxt26Q99iHJRiCQIIckR/mObkvy9+09r04fpcfxCPADA/AvvOBRvdmjD3Pd6WP8GnX8DcAGXsUNYDQPr4dAGh0qV/uHomH16c+bIzygUO1FVEFHfLZUhyvN+UjIVrX+iwlXCs+Juf18a/1mJ/DHK+XpckozGowfBXPD8lvhzU7KCG8BvinZ/UvMUbe5aUsFsCsb60yZ/7Nx9ptcsSN1n0jILm6B7mw3rzWQcmQmErMGq/z7xuqeAklHGc5GuVIVzJ+NzPyiDHjQblxYE0iiTpCv0xdIDnl51/+EDOJhJcjc= seki@yu
    EOF
}

resource "proxmox_vm_qemu" "acolyte-02" {
  name        = "acolyte-02"
  desc        = "kubernetes"
  vmid        = "1032"
  target_node = "shar"
  agent       = 0

  clone      = "debian-12-cloudinit"
  full_clone = true
  cores      = 4
  sockets    = 1
  cpu        = "host"
  memory     = 2048
  scsihw     = "virtio-scsi-pci"
  onboot     = true

  os_type    = "cloud-init"
  ipconfig0  = "ip=192.168.0.32/24,gw=192.168.0.1"
  nameserver = "192.168.0.3"
  ssh_user   = "kube"
  sshkeys    = <<EOF
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDLV/+WnYhO2RNlMCFqbgajQGGNV/yPesECbO5L1bZBNGHD4p7HaqO0YCmrAV6KcM3hE/n3hUIJ51xBKJppcgqGAhwxnAzb/FqT1h4UjSMa/qeCtypJJMzEddTniCPJJ8khfSeDa/Axu3hli7N12P6svUIdSDBil2kRbAWIZ9jMEX37fD7vu6qC4XI+wpe4kh6+aSO8TrZfAkY32udRp9noPcLbtuEbU+p8lIkTDDrCju3UOCzv4uqVdf47q/UQ9LP1kUcYmx1umR5eP/bthqSEpGC9M8vv50jo+BYL1mR6SOya//jbeYBaES1iDcIZbsx6HXjBX4nvKV/T2Ik/q0M/a8OhEVN4daZGLbyBiChuGidKU9OtXYOud5IBPPECiqZcZ3mnIFQGxuoPziuIopxgwCevbZEcL7rv4fbz0bl5+Y5r05dJhzoSjANsIdoyYXqjRitj87xzH6wPZOdBnHvTIAMxI4quEyPpVtajxZuDr04G6UyuIrKhhyPtm9qlLPU= coal@stone
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDFr6EdUZiVh5LIAZgukLDp93gj/ktEyoNUjcE8QSG3Zovf9VABlxkPY9f7KnQaAB3AeMhEIWYpZbHkMgF2l3TMuhPwp7VABds9lLHdb0YuZYL4Y7peRRhNSF6oDOetOkFt46nTs123aChCfj8UrhIR04PqP//LCBQ/gsS+XEDH4jlYGXCtEfOHgwHNFZPwu9aRA+xTj/5OWxr8e8Qtas8RFxt26Q99iHJRiCQIIckR/mObkvy9+09r04fpcfxCPADA/AvvOBRvdmjD3Pd6WP8GnX8DcAGXsUNYDQPr4dAGh0qV/uHomH16c+bIzygUO1FVEFHfLZUhyvN+UjIVrX+iwlXCs+Juf18a/1mJ/DHK+XpckozGowfBXPD8lvhzU7KCG8BvinZ/UvMUbe5aUsFsCsb60yZ/7Nx9ptcsSN1n0jILm6B7mw3rzWQcmQmErMGq/z7xuqeAklHGc5GuVIVzJ+NzPyiDHjQblxYE0iiTpCv0xdIDnl51/+EDOJhJcjc= seki@yu
    EOF
}

resource "proxmox_vm_qemu" "neophyte-00" {
  name        = "neophyte-00"
  desc        = "kubernetes"
  vmid        = "1040"
  target_node = "selune"
  agent       = 0

  clone      = "debian-12-cloudinit"
  full_clone = true
  cores      = 4
  sockets    = 1
  cpu        = "host"
  memory     = 2048
  scsihw     = "virtio-scsi-pci"
  onboot     = true

  os_type    = "cloud-init"
  ipconfig0  = "ip=192.168.0.40/24,gw=192.168.0.1"
  nameserver = "192.168.0.3"
  ssh_user   = "kube"
  sshkeys    = <<EOF
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDLV/+WnYhO2RNlMCFqbgajQGGNV/yPesECbO5L1bZBNGHD4p7HaqO0YCmrAV6KcM3hE/n3hUIJ51xBKJppcgqGAhwxnAzb/FqT1h4UjSMa/qeCtypJJMzEddTniCPJJ8khfSeDa/Axu3hli7N12P6svUIdSDBil2kRbAWIZ9jMEX37fD7vu6qC4XI+wpe4kh6+aSO8TrZfAkY32udRp9noPcLbtuEbU+p8lIkTDDrCju3UOCzv4uqVdf47q/UQ9LP1kUcYmx1umR5eP/bthqSEpGC9M8vv50jo+BYL1mR6SOya//jbeYBaES1iDcIZbsx6HXjBX4nvKV/T2Ik/q0M/a8OhEVN4daZGLbyBiChuGidKU9OtXYOud5IBPPECiqZcZ3mnIFQGxuoPziuIopxgwCevbZEcL7rv4fbz0bl5+Y5r05dJhzoSjANsIdoyYXqjRitj87xzH6wPZOdBnHvTIAMxI4quEyPpVtajxZuDr04G6UyuIrKhhyPtm9qlLPU= coal@stone
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDFr6EdUZiVh5LIAZgukLDp93gj/ktEyoNUjcE8QSG3Zovf9VABlxkPY9f7KnQaAB3AeMhEIWYpZbHkMgF2l3TMuhPwp7VABds9lLHdb0YuZYL4Y7peRRhNSF6oDOetOkFt46nTs123aChCfj8UrhIR04PqP//LCBQ/gsS+XEDH4jlYGXCtEfOHgwHNFZPwu9aRA+xTj/5OWxr8e8Qtas8RFxt26Q99iHJRiCQIIckR/mObkvy9+09r04fpcfxCPADA/AvvOBRvdmjD3Pd6WP8GnX8DcAGXsUNYDQPr4dAGh0qV/uHomH16c+bIzygUO1FVEFHfLZUhyvN+UjIVrX+iwlXCs+Juf18a/1mJ/DHK+XpckozGowfBXPD8lvhzU7KCG8BvinZ/UvMUbe5aUsFsCsb60yZ/7Nx9ptcsSN1n0jILm6B7mw3rzWQcmQmErMGq/z7xuqeAklHGc5GuVIVzJ+NzPyiDHjQblxYE0iiTpCv0xdIDnl51/+EDOJhJcjc= seki@yu
    EOF
}

resource "proxmox_vm_qemu" "neophyte-01" {
  name        = "neophyte-01"
  desc        = "kubernetes"
  vmid        = "1041"
  target_node = "shar"
  agent       = 0

  clone      = "debian-12-cloudinit"
  full_clone = true
  cores      = 4
  sockets    = 1
  cpu        = "host"
  memory     = 2048
  scsihw     = "virtio-scsi-pci"
  onboot     = true

  os_type    = "cloud-init"
  ipconfig0  = "ip=192.168.0.41/24,gw=192.168.0.1"
  nameserver = "192.168.0.3"
  ssh_user   = "kube"
  sshkeys    = <<EOF
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDLV/+WnYhO2RNlMCFqbgajQGGNV/yPesECbO5L1bZBNGHD4p7HaqO0YCmrAV6KcM3hE/n3hUIJ51xBKJppcgqGAhwxnAzb/FqT1h4UjSMa/qeCtypJJMzEddTniCPJJ8khfSeDa/Axu3hli7N12P6svUIdSDBil2kRbAWIZ9jMEX37fD7vu6qC4XI+wpe4kh6+aSO8TrZfAkY32udRp9noPcLbtuEbU+p8lIkTDDrCju3UOCzv4uqVdf47q/UQ9LP1kUcYmx1umR5eP/bthqSEpGC9M8vv50jo+BYL1mR6SOya//jbeYBaES1iDcIZbsx6HXjBX4nvKV/T2Ik/q0M/a8OhEVN4daZGLbyBiChuGidKU9OtXYOud5IBPPECiqZcZ3mnIFQGxuoPziuIopxgwCevbZEcL7rv4fbz0bl5+Y5r05dJhzoSjANsIdoyYXqjRitj87xzH6wPZOdBnHvTIAMxI4quEyPpVtajxZuDr04G6UyuIrKhhyPtm9qlLPU= coal@stone
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDFr6EdUZiVh5LIAZgukLDp93gj/ktEyoNUjcE8QSG3Zovf9VABlxkPY9f7KnQaAB3AeMhEIWYpZbHkMgF2l3TMuhPwp7VABds9lLHdb0YuZYL4Y7peRRhNSF6oDOetOkFt46nTs123aChCfj8UrhIR04PqP//LCBQ/gsS+XEDH4jlYGXCtEfOHgwHNFZPwu9aRA+xTj/5OWxr8e8Qtas8RFxt26Q99iHJRiCQIIckR/mObkvy9+09r04fpcfxCPADA/AvvOBRvdmjD3Pd6WP8GnX8DcAGXsUNYDQPr4dAGh0qV/uHomH16c+bIzygUO1FVEFHfLZUhyvN+UjIVrX+iwlXCs+Juf18a/1mJ/DHK+XpckozGowfBXPD8lvhzU7KCG8BvinZ/UvMUbe5aUsFsCsb60yZ/7Nx9ptcsSN1n0jILm6B7mw3rzWQcmQmErMGq/z7xuqeAklHGc5GuVIVzJ+NzPyiDHjQblxYE0iiTpCv0xdIDnl51/+EDOJhJcjc= seki@yu
    EOF
}