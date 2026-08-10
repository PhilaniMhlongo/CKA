#!/bin/bash
# LabSetUp.bash for Question 25 - CoreDNS
set -uo pipefail

WORKDIR="${WORKDIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/coredns-state}"
mkdir -p "$WORKDIR"

echo "Backing up the working Corefile..."
kubectl get configmap coredns -n kube-system -o yaml > "$WORKDIR/coredns-configmap.bak.yaml"

echo "Creating the namespace and workloads..."
kubectl create namespace dns-lab --dry-run=client -o yaml | kubectl apply -f -

cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: dns-lab
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: nginx
        image: nginx:stable
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: backend
  namespace: dns-lab
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 80
EOF

echo "Breaking upstream DNS forwarding..."
# The forward plugin is pointed at a reserved, unroutable address, so in-cluster
# names still resolve but anything CoreDNS must forward upstream times out. The
# rest of the Corefile is untouched, so the fault has to be found by reading it.
kubectl get configmap coredns -n kube-system -o yaml \
  | sed 's|forward \. /etc/resolv\.conf|forward . 240.0.0.1|' \
  | kubectl apply -f - >/dev/null

kubectl rollout restart deployment coredns -n kube-system >/dev/null
kubectl rollout status deployment coredns -n kube-system --timeout=90s >/dev/null 2>&1

echo ""
echo "[OK] Lab setup complete."
echo "Namespace 'dns-lab' has a 'backend' Deployment and Service."
echo "Corefile backup written to $WORKDIR/coredns-configmap.bak.yaml"
