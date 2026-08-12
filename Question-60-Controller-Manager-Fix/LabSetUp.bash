#!/bin/bash
set -e

MANIFEST=/etc/kubernetes/manifests/kube-controller-manager.yaml
if [[ ! -f "$MANIFEST" ]]; then
  echo "ERROR: $MANIFEST not found."
  echo "This lab must run ON the control-plane node of a kubeadm cluster (e.g. Killercoda)."
  exit 1
fi

WORKDIR="${WORKDIR:-$PWD/kcm-backup}"
mkdir -p "$WORKDIR"

echo "Backing up the kube-controller-manager manifest to $WORKDIR ..."
cp "$MANIFEST" "$WORKDIR/kube-controller-manager.yaml.bak"

echo "Breaking the kube-controller-manager (wrong kubeconfig path)..."
sed -i 's|--kubeconfig=/etc/kubernetes/controller-manager.conf|--kubeconfig=/etc/kubernetes/controller-manager-missing.conf|' "$MANIFEST"

echo "Waiting for the kubelet to pick up the broken manifest..."
sleep 20

echo "Creating namespace and a test deployment (its pods will NOT appear)..."
kubectl create namespace d8f3b6a1c2e4-kcm-fix --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kcm-test
  namespace: d8f3b6a1c2e4-kcm-fix
spec:
  replicas: 2
  selector:
    matchLabels:
      app: kcm-test
  template:
    metadata:
      labels:
        app: kcm-test
    spec:
      containers:
        - name: nginx
          image: nginx
EOF

echo "[OK] Lab setup complete."
echo "   - Symptom: 'kcm-test' deployment exists but creates no ReplicaSet/pods."
echo "   - A backup of the original manifest is in $WORKDIR (for emergencies)."
