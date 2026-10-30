resource "google_compute_instance" "node" {
  name         = var.name
  zone         = var.zone
  machine_type = var.machine_type
  tags         = var.network_tags

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = var.boot_disk_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = var.subnet_id
    # No access_config: nodes have no public IP address.
  }

  metadata = {
    "enable-oslogin" = "TRUE"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }
}
