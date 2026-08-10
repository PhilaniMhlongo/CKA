#!/bin/bash
# LabSetUp.bash for Question 24 - kubeadm upgrade
set -uo pipefail

# Generated state lives in the question's own working directory, not /root,
# so this works the same on a local cluster as it does on Killercoda.
WORKDIR="${WORKDIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/upgrade-state}"
mkdir -p "$WORKDIR"

CONTROLPLANE=$(kubectl get nodes \
  -l node-role.kubernetes.io/control-plane \
  -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [[ -z "$CONTROLPLANE" ]]; then
  echo "ERROR: could not find a control-plane node. This lab must run against a"
  echo "kubeadm-built cluster where you have root on the controlplane node."
  exit 1
fi

BASELINE=$(kubectl get node "$CONTROLPLANE" -o jsonpath='{.status.nodeInfo.kubeletVersion}')

# Record the starting point so validate.bash can tell whether an upgrade actually
# happened, rather than hard-coding a version that will rot.
printf '%s\n' "$CONTROLPLANE" > "$WORKDIR/controlplane-node"
printf '%s\n' "$BASELINE" > "$WORKDIR/baseline-version"

echo "Controlplane node : $CONTROLPLANE"
echo "Baseline version  : $BASELINE"

echo ""
echo "Deploying a workload that should survive the upgrade..."
kubectl create namespace upgrade-demo --dry-run=client -o yaml | kubectl apply -f -
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: survivor
  namespace: upgrade-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: survivor
  template:
    metadata:
      labels:
        app: survivor
    spec:
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      containers:
      - name: nginx
        image: nginx:stable
EOF

echo ""
echo "Available upgrade targets (this may take a moment):"
sudo kubeadm upgrade plan 2>/dev/null | sed -n '1,40p' || \
  echo "  (run 'sudo kubeadm upgrade plan' yourself to see the options)"

echo ""
echo "[OK] Lab setup complete. Baseline recorded in $WORKDIR/baseline-version"
echo "Upgrade the controlplane to the next patch version of its current minor release."
