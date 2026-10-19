# Sample Project: Deploy Infrastructure on GCP Using Terraform

Here is a practical, portfolio-ready DevOps project using Google Cloud Platform (GCP) + Terraform. It demonstrates Infrastructure as Code (IaC), cloud networking, virtual machines, security, and automated infrastructure deployment.

## Project overview

Project name: Deploy a Secure Web Server on GCP Using Terraform

Objective: Create a GCP environment using Terraform that deploys a Linux VM running Nginx, configures networking and firewall rules, and allows you to manage the entire infrastructure through code.

Terraform for Dummies Part 4: Launch a VM with a Static Website on a Google Cloud Platform — Eclipsys | by Cloud Dude | Medium

### Architecture

Internet / Web Browser

GCP VPC Network

Custom subnet · Firewall rules

Compute Engine VM

Ubuntu Linux + Nginx

HTTP server on port 80

Terraform

Creates, updates and destroys infrastructure

## 1. Technologies used

- Cloud: Google Cloud Platform
- IaC: Terraform
- Compute: Compute Engine VM
- Networking: VPC, subnet and firewall
- Operating system: Ubuntu Linux
- Web server: Nginx
- Version control: Git and GitHub
- Authentication: Google Cloud Application Default Credentials

## 2. Project folder structure

Create a directory named `gcp-terraform-webserver` with the following files:

text
```
gcp-terraform-webserver/
├── providers.tf
├── variables.tf
├── main.tf
├── outputs.tf
├── terraform.tfvars
└── .gitignore
```

Each file has a specific purpose:

| File | Purpose |
| --- | --- |
| `providers.tf` | Configures Terraform and the GCP provider |
| `variables.tf` | Declares configurable inputs |
| `main.tf` | Defines the cloud infrastructure |
| `outputs.tf` | Displays the VM's public IP |
| `terraform.tfvars` | Provides project-specific values |
| `.gitignore` | Excludes local state and sensitive files from Git |

## 3. Configure the GCP provider

Create `providers.tf`:

hcl
```

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}
```

This configures Terraform to use the official Google provider. Terraform downloads the provider when you initialize the project.

## 4. Define input variables

Create `variables.tf`:

hcl
```

variable "project_id" {
  description = "Your Google Cloud project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "asia-south1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "asia-south1-a"
}
```

The region above is Mumbai, India. You can change it to another supported GCP region and zone.

## 5. Create the infrastructure

Create `main.tf`:

hcl
```

# Create a custom VPC network
resource "google_compute_network" "vpc" {
  name                    = "terraform-vpc"
  auto_create_subnetworks = false
}

# Create a subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "terraform-subnet"
  ip_cidr_range = "10.10.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

# Allow HTTP traffic to the web server
resource "google_compute_firewall" "http" {
  name    = "allow-http"
  network = google_compute_network.vpc.name

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
}

# Create a Compute Engine VM
resource "google_compute_instance" "web" {
  name         = "terraform-web-server"
  machine_type = "e2-micro"
  zone         = var.zone

  tags = ["web-server"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 10
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {
      # Assign an ephemeral external IP
    }
  }

  metadata_startup_script = <<-SCRIPT
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx

    cat > /var/www/html/index.html <<'HTML'
    <!DOCTYPE html>
    <html>
      <head>
        <title>GCP Terraform Project</title>
      </head>
      <body>
        <h1>Hello from GCP!</h1>
        <p>This web server was deployed using Terraform.</p>
      </body>
    </html>
    HTML
  SCRIPT
}
```

### What this Terraform code creates

- A custom VPC network.
- A subnet with the `10.10.1.0/24` CIDR range.
- A firewall rule permitting inbound HTTP traffic on port 80 to tagged instances.
- A Compute Engine VM with Ubuntu Linux.
- An external IP address and a startup script that installs Nginx.

The startup script runs when the VM boots. Package installation requires the VM to have outbound internet access.

Security note: This is a learning environment. The HTTP rule intentionally allows internet access to port 80. For production, restrict access where possible, avoid exposing administration ports publicly, and consider a load balancer with HTTPS.

## 6. Configure the output

Create `outputs.tf`:

hcl
```

output "web_server_public_ip" {
  description = "External IP address of the web server"
  value       = google_compute_instance.web.network_interface[0].access_config[0].nat_ip
}

output "web_server_url" {
  description = "URL to access the Nginx web server"
  value       = "http://${google_compute_instance.web.network_interface[0].access_config[0].nat_ip}"
}
```

After deployment, Terraform will display the VM's external IP and website URL.

## 7. Set your GCP project values

Create `terraform.tfvars`:

hcl
```
project_id = "your-gcp-project-id"
region     = "asia-south1"
zone       = "asia-south1-a"
```

Replace `your-gcp-project-id` with your actual Google Cloud project ID. Do not use a service account key or other credentials as the project ID.

## 8. Authenticate and deploy

Before running Terraform, install the [Google Cloud CLI](<https://cloud.google.com/sdk/docs/install?utm_source=chatgpt.com>) and [Terraform](<https://developer.hashicorp.com/terraform/install?utm_source=chatgpt.com>), and create or select a GCP project with billing enabled.

Run these commands in your terminal.

Step 1: Authenticate

bash
```
gcloud auth login
gcloud auth application-default login
```

Use an account with permission to create the required GCP resources.

Step 2: Select the project and enable the API

bash
```
gcloud config set project YOUR_PROJECT_ID
gcloud services enable compute.googleapis.com
```

Step 3: Initialize Terraform

bash
```
terraform init
```

Downloads the Google provider and initializes the working directory.

Step 4: Validate the code

bash
```
terraform fmt
terraform validate
```

Formats the configuration and checks for errors.

Step 5: Review the deployment plan

bash
```
terraform plan
```

Review which resources Terraform intends to create before proceeding.

Step 6: Deploy

bash
```
terraform apply
```

Type `yes` when prompted after reviewing the plan.

Step 7: Get the website URL

bash
```
terraform output web_server_url
```

Open the resulting URL in your browser. The first request may fail while the VM installs Nginx; wait a minute and retry.

## 9. Add a `.gitignore` file

Create `.gitignore` to prevent local Terraform files and credentials from being committed to Git:

gitignore
```
.terraform/
*.tfstate
*.tfstate.*
*.tfplan
terraform.tfvars
crash.log
```

Keep your Terraform configuration in Git, but never commit credentials or Terraform state files. State can contain sensitive information. For team projects, use a properly secured GCS remote backend with state locking support and restricted IAM permissions.

## 10. Verify the deployed application

After the VM starts, run:

bash
```
terraform output -raw web_server_public_ip
```

Test the server using the returned IP address:

bash
```
curl http://YOUR_PUBLIC_IP
```

Expected response includes:

HTMLWrap linesCopy codePreview

```
<h1>Hello from GCP!</h1>
<p>This web server was deployed using Terraform.</p>
```

You can also check the VM in the Google Cloud Console under Compute Engine → VM instances.

## 11. Destroy the infrastructure

When you finish testing, remove the resources to avoid unnecessary cloud charges:

bash
```
terraform destroy
```

Review the proposed deletions and type `yes` to confirm.

Note that billing can depend on VM usage, disks, network traffic, and other resources. Check current GCP pricing and your project's free-tier eligibility before deployment.

## 12. Make this a stronger DevOps portfolio project

Once the basic project works, build on it in stages:

Level 1 — Terraform fundamentals

Start hereVariables, outputs, resources, validation, plans, and state management.

Level 2 — Reusable infrastructure

Create Terraform modules for VPC, subnet, firewall, and VM. Store remote state in a secured GCS bucket.

Level 3 — CI/CD automation

Use GitHub Actions to run fmt, validate, and plan on pull requests, then deploy through an approved workflow using Workload Identity Federation.

Level 4 — Production-style architecture

Add HTTPS, a load balancer, managed instance groups, monitoring, IAM least privilege, and separate development and production environments.

## 13. Suggested GitHub README description

Writing

# GCP Infrastructure Provisioning Using Terraform

## Overview

This project provisions a web server infrastructure on Google Cloud Platform using Terraform.

## Architecture

- Custom VPC and subnet
- Firewall rules for HTTP access
- Compute Engine virtual machine
- Ubuntu Linux and Nginx web server
- Terraform outputs for application access

## Tools

- Google Cloud Platform
- Terraform
- Google Cloud CLI
- Linux
- Git and GitHub

## Deployment

1. Authenticate with Google Cloud.
2. Configure the project ID in `terraform.tfvars`.
3. Run `terraform init`.
4. Run `terraform fmt` and `terraform validate`.
5. Review the infrastructure with `terraform plan`.
6. Deploy using `terraform apply`.
7. Access the web server using the output URL.
8. Clean up resources using `terraform destroy`.

## Learning Outcomes

- Infrastructure as Code
- Terraform resource dependencies and state
- GCP networking and compute
- Firewall configuration and cloud security
- Automated infrastructure provisioning

## Future Enhancements

- Reusable Terraform modules
- GCS remote state
- GitHub Actions CI/CD
- Workload Identity Federation
- HTTPS load balancing and monitoring

My recommendation: Complete this project manually first, confirm the website works, and then add modules and GitHub Actions. That progression gives you a concrete project to demonstrate in a DevOps interview, rather than just a collection of Terraform commands.
