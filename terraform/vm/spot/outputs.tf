output "vm_name" {
  description = "The name of the created Proxmox VM"
  value       = module.spot.vm_name
}

output "vm_id" {
  description = "The ID of the created Proxmox VM"
  value       = module.spot.vm_id
}
