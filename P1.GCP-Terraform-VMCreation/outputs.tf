
output "web_server_public_ip" {
  description = "External IP address of the web server"
  value       = google_compute_instance.web.network_interface[0].access_config[0].nat_ip
}

output "web_server_url" {
  description = "URL to access the Nginx web server"
  value       = "http://${google_compute_instance.web.network_interface[0].access_config[0].nat_ip}"
}
