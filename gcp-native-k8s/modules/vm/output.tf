output "name" {
  value = google_compute_instance.node.name
}

output "internal_ip" {
  value = google_compute_instance.node.network_interface[0].network_ip
}
