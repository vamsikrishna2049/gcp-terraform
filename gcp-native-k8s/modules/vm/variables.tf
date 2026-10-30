variable "name" {
  description = "Unique instance name."
  type        = string
}

variable "zone" {
  type = string
}

variable "machine_type" {
  type = string
}

variable "subnet_id" {
  description = "Subnetwork self-link for the instance NIC."
  type        = string
}

variable "network_tags" {
  type = list(string)
}

variable "boot_disk_gb" {
  type = number
}
