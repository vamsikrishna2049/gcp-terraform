output "control_plane_name" {
  description = "Name of the control-plane VM."
  value       = module.control_plane.name
}

output "control_plane_internal_ip" {
  description = "Private IP address of the control-plane VM."
  value       = module.control_plane.internal_ip
}

output "worker_internal_ips" {
  description = "Private IP addresses of the worker VMs."
  value       = { for name, vm in module.workers : name => vm.internal_ip }
}

output "zone" {
  description = "Zone containing the lab VMs."
  value       = var.zone
}
