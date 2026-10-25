variable "project_id" {
  description = "GCP project ID for the lab."
  type        = string
}

variable "name" {
  description = "Short prefix used to name lab resources."
  type        = string
  default     = "kubeadm-lab"
}

variable "region" {
  description = "GCP region for the subnet and Cloud NAT."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone for all lab VMs."
  type        = string
  default     = "us-central1-a"
}

variable "subnet_cidr" {
  description = "Private IPv4 range for the lab subnet."
  type        = string
  default     = "10.20.0.0/20"
}

variable "machine_type" {
  description = "Compute Engine machine type used for each node."
  type        = string
  default     = "e2-standard-2"
}

variable "boot_disk_gb" {
  description = "Boot disk size for each node in GB."
  type        = number
  default     = 40
}
