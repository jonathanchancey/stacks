output "vm_name" {
  description = "The name of the created Proxmox VM"
  value       = proxmox_virtual_environment_vm.vm.name
}

output "vm_id" {
  description = "The ID of the created Proxmox VM"
  value       = proxmox_virtual_environment_vm.vm.id
}

output "vm_ipv6_addresses" {
  description = "The IPv6 address assigned to the VM via DHCP"
  value       = proxmox_virtual_environment_vm.vm.ipv6_addresses
}

output "vm_ipv4_addresses" {
  description = "The IPv6 address assigned to the VM via DHCP"
  value       = proxmox_virtual_environment_vm.vm.ipv4_addresses
}
