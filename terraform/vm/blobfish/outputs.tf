output "vm_name" {
  description = "The name of the created Proxmox VM"
  value       = { for k, v in module.vm : k => v.vm_name }
}

output "vm_id" {
  description = "The ID of the created Proxmox VM"
  value       = { for k, v in module.vm : k => v.vm_id }
}

output "vm_ipv4_address" {
  description = "The IPv4 address assigned to the VM via DHCP"
  value       = { for k, v in module.vm : k => (length(v.vm_ipv4_addresses) > 1 && length(v.vm_ipv4_addresses[1]) > 0 ? v.vm_ipv4_addresses[1][0] : null) }
}
