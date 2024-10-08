output "vm_name" {
  description = "The name of the created Proxmox VM"
  value       = { for k, v in module.vm : k => v.vm_name }
}

output "vm_id" {
  description = "The ID of the created Proxmox VM"
  value       = { for k, v in module.vm : k => v.vm_id }
}

output "vm_ipv6_address" {
  description = "The IPv6 address assigned to the VM via DHCP"
  value       = { for k, v in module.vm : k => (length(v.vm_ipv6_addresses) > 1 && length(v.vm_ipv6_addresses[1]) > 0 ? v.vm_ipv6_addresses[1][0] : null) }
}

output "vm_ipv4_address" {
  description = "The IPv6 address assigned to the VM via DHCP"
  value       = { for k, v in module.vm : k => (length(v.vm_ipv4_addresses) > 1 && length(v.vm_ipv4_addresses[1]) > 0 ? v.vm_ipv4_addresses[1][0] : null) }
}

output "ansible_hosts" {
  description = "The ID of the created Proxmox VM"
  value       = { for k, v in ansible_host.vms : k => v.groups }
}
