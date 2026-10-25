terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0, < 8.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

module "network" {
  source = "./modules/network"

  name        = var.name
  region      = var.region
  subnet_cidr = var.subnet_cidr
}

module "control_plane" {
  source = "./modules/vm"

  name         = "${var.name}-control-plane"
  zone         = var.zone
  machine_type = var.machine_type
  subnet_id    = module.network.subnet_id
  network_tags = ["${var.name}-node", "${var.name}-control-plane"]
  boot_disk_gb = var.boot_disk_gb
}

module "workers" {
  source   = "./modules/vm"
  for_each = toset(["worker-1", "worker-2"])

  name         = "${var.name}-${each.key}"
  zone         = var.zone
  machine_type = var.machine_type
  subnet_id    = module.network.subnet_id
  network_tags = ["${var.name}-node"]
  boot_disk_gb = var.boot_disk_gb
}

