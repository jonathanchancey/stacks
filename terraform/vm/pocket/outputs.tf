output "vm_name" {
  description = "The name of the created Proxmox VM"
  value       = module.pocket.vm_name
}

output "vm_id" {
  description = "The ID of the created Proxmox VM"
  value       = module.pocket.vm_id
}

output "vm_ipv6_address" {
  description = "The IPv6 address assigned to the VM via DHCP"
  value       = module.pocket.vm_ipv6_addresses[1][0]
}
