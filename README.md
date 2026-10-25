# Kubeadm lab on GCP

A small, private Compute Engine lab for learning Kubernetes with kubeadm:

- 1 control-plane VM and 2 worker VMs
- Custom VPC and subnet
- Cloud NAT for outbound package downloads; VMs have no public IPs
- IAP TCP forwarding for SSH and the Kubernetes API
- Terraform modules for network and VM resources

This provisions the VM infrastructure only. It does not install or configure Kubernetes yet.

## Prerequisites

- A GCP project with billing enabled
- Terraform 1.5 or newer
- `gcloud` CLI, authenticated with an account allowed to create Compute Engine, VPC, Cloud NAT, and firewall resources
- IAP TCP forwarding enabled for your project, plus the `roles/iap.tunnelResourceAccessor` and OS Login permissions needed for your account

Enable these APIs before applying: Compute Engine API (`compute.googleapis.com`) and Cloud Resource Manager API (`cloudresourcemanager.googleapis.com`).

## Configure and provision

From this directory, copy `terraform.tfvars.example` to `terraform.tfvars` and set `project_id`.

```sh
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

Review the plan before applying. The VMs, NAT gateway, and related network resources incur charges while they exist. Remove the lab when finished with `terraform destroy`.

## Connect

Use IAP to connect to a VM without a public IP:

```sh
gcloud compute ssh kubeadm-control-plane --zone us-central1-a --tunnel-through-iap
```

To reach the Kubernetes API from your workstation, open an IAP tunnel in one terminal:

```sh
gcloud compute start-iap-tunnel kubeadm-control-plane 6443 --local-host-port=localhost:6443 --zone us-central1-a
```

The tunnel forwards local port 6443 to the VM. The simplest first workflow is to run `kubectl` on the control-plane VM. For local `kubectl`, configure kubeadm's API certificate SANs to include `localhost` and `127.0.0.1`, then point the local kubeconfig at `https://127.0.0.1:6443` while the tunnel is running. Worker-to-control-plane traffic uses the private subnet.

The VMs use Ubuntu 24.04 LTS. Continue the lab by installing containerd and matching Kubernetes packages on all three VMs, initializing the control plane with kubeadm, then joining the workers. Follow the current official Kubernetes kubeadm installation guide for package-repository and runtime setup.

## GitHub workflow

The included GitHub Actions workflow runs Terraform formatting and validation on pull requests. It does not authenticate to GCP or apply changes. When you are ready, configure GitHub-to-GCP Workload Identity Federation for a plan-only workflow, restricting trust to this repository and the intended branch. Keep `terraform.tfvars`, state files, and credentials out of Git.

## Layout

- `main.tf`, `variables.tf`, `outputs.tf`: lab composition and inputs/outputs
- `modules/network`: VPC, subnet, Cloud NAT, and firewall rules
- `modules/vm`: reusable private VM definition
- `.github/workflows/terraform.yml`: formatting and validation checks

