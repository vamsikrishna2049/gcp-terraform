resource "google_compute_network" "lab" {
  name                    = "${var.name}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "lab" {
  name                     = "${var.name}-subnet"
  region                   = var.region
  ip_cidr_range             = var.subnet_cidr
  network                  = google_compute_network.lab.id
  private_ip_google_access = true
}

resource "google_compute_router" "lab" {
  name    = "${var.name}-router"
  region  = var.region
  network = google_compute_network.lab.id
}

resource "google_compute_router_nat" "lab" {
  name                               = "${var.name}-nat"
  router                             = google_compute_router.lab.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_firewall" "iap_ssh" {
  name      = "${var.name}-iap-ssh"
  network   = google_compute_network.lab.name
  direction = "INGRESS"

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["${var.name}-node"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "iap_api" {
  name      = "${var.name}-iap-api"
  network   = google_compute_network.lab.name
  direction = "INGRESS"

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["${var.name}-control-plane"]

  allow {
    protocol = "tcp"
    ports    = ["6443"]
  }
}

resource "google_compute_firewall" "internal_nodes" {
  name      = "${var.name}-internal-nodes"
  network   = google_compute_network.lab.name
  direction = "INGRESS"

  source_ranges = [var.subnet_cidr]
  target_tags   = ["${var.name}-node"]

  allow {
    protocol = "all"
  }
}
