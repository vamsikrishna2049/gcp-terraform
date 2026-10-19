## 1. Install Google Cloud CLI on Ubuntu 24.04

These steps follow Google's Debian/Ubuntu installation method. Official documentation: [Install the Google Cloud CLI](<https://docs.cloud.google.com/sdk/docs/install-sdk?utm_source=chatgpt.com#deb>)

### Step 1: Update packages and install prerequisites

Run:

bash
```
sudo apt-get update
sudo apt-get install -y ca-certificates gnupg curl
```

### Step 2: Add Google's APT signing key

Create the keyring directory and download Google's signing key:

bash
```
sudo install -d -m 0755 /usr/share/keyrings

curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
  | sudo gpg --dearmor --yes \
  -o /usr/share/keyrings/cloud.google.gpg

sudo chmod 0644 /usr/share/keyrings/cloud.google.gpg
```

This allows APT to verify packages signed by Google.

### Step 3: Add Google's APT repository

Run:

bash
```
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
  | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
```

This configures APT to download Google Cloud CLI packages from Google's official repository.

Google Cloud Documentation

### Step 4: Install Google Cloud CLI

Run:

bash
```
sudo apt-get update
sudo apt-get install -y google-cloud-cli
```

APT will download and install the CLI and its required dependencies.

### Step 5: Verify the installation

Check the installed version:

bash
```
gcloud --version
```

You should see output listing the Google Cloud CLI version and its installed components, such as `gsutil` and `bq`.

## 2. Initialize and authenticate

Once the installation is complete, run:

bash
```
gcloud init
```

Follow the prompts to:

1. Sign in to your Google account through the browser.
2. Select an existing Google Cloud project or choose a project you have permission to access.
3. Configure a default region or zone if prompted.

To verify your active account and project:

bash
```
gcloud auth list
gcloud config list
```

To see your current project ID:

bash
```
gcloud config get-value project
```

If you need to authenticate again later, use:

bash
```
gcloud auth login
```

## 3. Optional: Install additional tools

The base `google-cloud-cli` package does not include `kubectl` or the GKE authentication plugin. If you work with Google Kubernetes Engine, install them separately:

bash
```
sudo apt-get install -y kubectl google-cloud-cli-gke-gcloud-auth-plugin
```

For ordinary Google Cloud operations, such as managing Compute Engine VMs, Cloud Storage buckets, and IAM resources, the base CLI is sufficient.

Google Cloud Documentation

## 4\. Quick verification checklist

Run these commands after installation:

bash
```
gcloud --version
gcloud auth list
gcloud config list
```
