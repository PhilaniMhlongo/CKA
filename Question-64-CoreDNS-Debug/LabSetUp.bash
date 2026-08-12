#!/bin/bash
set -e

if ! kubectl get configmap coredns -n kube-system >/dev/null 2>&1; then
  echo "ERROR: coredns configmap not found in kube-system. This lab needs a CoreDNS cluster."
  exit 1
fi

WORKDIR="${WORKDIR:-$PWD/coredns-backup}"
mkdir -p "$WORKDIR"

echo "Backing up the CoreDNS ConfigMap and replica count to $WORKDIR ..."
kubectl get configmap coredns -n kube-system -o yaml > "$WORKDIR/coredns-cm.yaml.bak"
kubectl get deployment coredns -n kube-system -o jsonpath='{.spec.replicas}' > "$WORKDIR/coredns-replicas.bak"

echo "Breaking cluster DNS (corrupting the Corefile zone + scaling CoreDNS down)..."
kubectl get configmap coredns -n kube-system -o yaml \
  | sed 's/cluster\.local/cluster.broken/g' \
  | kubectl apply -f -
kubectl scale deployment coredns -n kube-system --replicas=0

echo "Creating namespace and a DNS test client..."
kubectl create namespace d8f3b6a1c2e4-dns-debug --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: dns-client
  namespace: d8f3b6a1c2e4-dns-debug
spec:
  containers:
    - name: busybox
      image: busybox:1.36
      command: ["sleep", "3600"]
EOF

echo "[OK] Lab setup complete."
echo "   - Cluster-wide service DNS is now BROKEN (two separate causes)."
echo "   - Test client: dns-client in d8f3b6a1c2e4-dns-debug"
echo "   - Emergency backup: $WORKDIR/coredns-cm.yaml.bak"
