output "network_id" {
  value = google_compute_network.lab.id
}

output "subnet_id" {
  value = google_compute_subnetwork.lab.id
}
