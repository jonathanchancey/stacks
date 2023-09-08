resource "proxmox_vm_qemu" "acolyte" {
    name = "acolyte"
    desc = "ubuntu-server"
    vmid = "200"
    target_node = "selune"

    agent = 1

    clone = "ubuntu-server-23.04-virtio"
    cores = 2
    sockets = 1 
    cpu = "host"
    memory = 3072

    network {
        bridge = "vmbr0"
        model = "virtio"
    }

    disk {
        storage = "local-lvm"
        type = "virtio"
        size = "20G"
    }

    os_type = "cloud-init"
    ipconfig0 = "ip=192.168.0.30/24,gw=192.168.0.1"
    nameserver = "192.168.0.3"
    ssh_user = "root"
    sshkeys = <<EOF
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDFr6EdUZiVh5LIAZgukLDp93gj/ktEyoNUjcE8QSG3Zovf9VABlxkPY9f7KnQaAB3AeMhEIWYpZbHkMgF2l3TMuhPwp7VABds9lLHdb0YuZYL4Y7peRRhNSF6oDOetOkFt46nTs123aChCfj8UrhIR04PqP//LCBQ/gsS+XEDH4jlYGXCtEfOHgwHNFZPwu9aRA+xTj/5OWxr8e8Qtas8RFxt26Q99iHJRiCQIIckR/mObkvy9+09r04fpcfxCPADA/AvvOBRvdmjD3Pd6WP8GnX8DcAGXsUNYDQPr4dAGh0qV/uHomH16c+bIzygUO1FVEFHfLZUhyvN+UjIVrX+iwlXCs+Juf18a/1mJ/DHK+XpckozGowfBXPD8lvhzU7KCG8BvinZ/UvMUbe5aUsFsCsb60yZ/7Nx9ptcsSN1n0jILm6B7mw3rzWQcmQmErMGq/z7xuqeAklHGc5GuVIVzJ+NzPyiDHjQblxYE0iiTpCv0xdIDnl51/+EDOJhJcjc= seki@yu
    EOF 
}