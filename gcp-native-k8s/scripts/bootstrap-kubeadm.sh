#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
TFVARS_FILE="${TFVARS_FILE:-${REPO_ROOT}/terraform.tfvars}"

if [[ ! -f "$TFVARS_FILE" ]]; then
  echo "Cannot find $TFVARS_FILE" >&2
  exit 1
fi

PROJECT_ID="$(
  awk -F= '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*project_id[[:space:]]*=/ {
      value = $2
      sub(/[[:space:]]+#.*/, "", value)
      gsub(/^[[:space:]"]+|[[:space:]"]+$/, "", value)
      print value
      exit
    }
  ' "$TFVARS_FILE"
)"

if [[ -z "$PROJECT_ID" ]]; then
  echo "project_id was not found in $TFVARS_FILE" >&2
  exit 1
fi

ZONE="${1:-us-central1-a}"
CONTROL_PLANE="kubeadm-lab-control-plane"
WORKERS=("kubeadm-lab-worker-1" "kubeadm-lab-worker-2")
POD_CIDR="10.244.0.0/16"
K8S_MINOR="v1.37"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v gcloud >/dev/null 2>&1; then
  echo "gcloud is required. Run this from Google Cloud Shell or install gcloud first." >&2
  exit 1
fi

if ! gcloud auth list --filter=status:ACTIVE --format='value(account)' | grep -q .; then
  echo "No active gcloud account. Run: gcloud auth login" >&2
  exit 1
fi

cat > "$TMP_DIR/node-setup.sh" <<'NODE'
#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get -o DPkg::Lock::Timeout=600 update
apt-get -o DPkg::Lock::Timeout=600 install -y \
  apt-transport-https ca-certificates curl gpg containerd

swapoff -a
if grep -qE '^[^#].*[[:space:]]swap[[:space:]]' /etc/fstab; then
  sed -i -E '/^[^#].*[[:space:]]swap[[:space:]]/s/^/#/' /etc/fstab
fi

modprobe overlay
modprobe br_netfilter
cat > /etc/modules-load.d/k8s.conf <<'EOF'
overlay
br_netfilter
EOF

cat > /etc/sysctl.d/k8s.conf <<'EOF'
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl enable --now containerd

K8S_MINOR="v1.37"
mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL "https://pkgs.k8s.io/core:/stable:/${K8S_MINOR}/deb/Release.key" \
  | gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_MINOR}/deb/ /" \
  > /etc/apt/sources.list.d/kubernetes.list

apt-get -o DPkg::Lock::Timeout=600 update
apt-get -o DPkg::Lock::Timeout=600 install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
systemctl enable --now kubelet
NODE

remote() {
  local instance="$1"
  local command="$2"
  gcloud compute ssh "$instance" \
    --project="$PROJECT_ID" \
    --zone="$ZONE" \
    --tunnel-through-iap \
    --quiet \
    --command="$command"
}

prepare_node() {
  local instance="$1"
  echo "Preparing ${instance}..."
  gcloud compute scp "$TMP_DIR/node-setup.sh" "${instance}:/tmp/node-setup.sh" \
    --project="$PROJECT_ID" \
    --zone="$ZONE" \
    --tunnel-through-iap \
    --quiet
  remote "$instance" "sudo bash /tmp/node-setup.sh"
}

CONTROL_PLANE_IP="$(
  gcloud compute instances describe "$CONTROL_PLANE" \
    --project="$PROJECT_ID" \
    --zone="$ZONE" \
    --format='get(networkInterfaces[0].networkIP)'
)"

if [[ -z "$CONTROL_PLANE_IP" ]]; then
  echo "Could not find the control-plane VM's private IP." >&2
  exit 1
fi

prepare_node "$CONTROL_PLANE"
for worker in "${WORKERS[@]}"; do
  prepare_node "$worker"
done

echo "Initializing the control plane..."
remote "$CONTROL_PLANE" \
  "if sudo test -s /etc/kubernetes/admin.conf; then echo 'Already initialized'; else sudo kubeadm init --apiserver-advertise-address=${CONTROL_PLANE_IP} --pod-network-cidr=${POD_CIDR}; fi"

remote "$CONTROL_PLANE" \
  'mkdir -p "$HOME/.kube" && sudo install -o "$(id -u)" -g "$(id -g)" -m 600 /etc/kubernetes/admin.conf "$HOME/.kube/config"'

remote "$CONTROL_PLANE" \
  'kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml'

remote "$CONTROL_PLANE" \
  'kubectl wait --for=condition=Ready node --all --timeout=5m'

JOIN_COMMAND="$(
  remote "$CONTROL_PLANE" 'sudo kubeadm token create --print-join-command' \
    | grep -E '^kubeadm join ' \
    | tail -n 1
)"

if [[ -z "$JOIN_COMMAND" ]]; then
  echo "Could not get a kubeadm join command from the control plane." >&2
  exit 1
fi

for worker in "${WORKERS[@]}"; do
  echo "Joining ${worker}..."
  remote "$worker" \
    "if sudo test -s /etc/kubernetes/kubelet.conf; then echo 'Already joined'; else sudo ${JOIN_COMMAND}; fi"
done

remote "$CONTROL_PLANE" 'kubectl wait --for=condition=Ready node --all --timeout=5m'
remote "$CONTROL_PLANE" 'kubectl get nodes -o wide'