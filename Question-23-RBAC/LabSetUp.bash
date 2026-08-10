#!/bin/bash
# LabSetUp.bash for Question 23 - RBAC
set -uo pipefail

echo "Creating namespaces..."
kubectl create namespace finance --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace hr --dry-run=client -o yaml | kubectl apply -f -

echo "Creating the ServiceAccount the task refers to..."
kubectl create serviceaccount report-runner -n finance \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Creating a workload for the ServiceAccount to be used by..."
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: reporter
  namespace: finance
spec:
  replicas: 1
  selector:
    matchLabels:
      app: reporter
  template:
    metadata:
      labels:
        app: reporter
    spec:
      serviceAccountName: report-runner
      containers:
      - name: reporter
        image: busybox:stable
        command: ["sh", "-c", "sleep 3600"]
EOF

echo "Creating some objects for the ServiceAccount to read..."
kubectl create configmap quarterly-figures -n finance \
  --from-literal=q1=100 --from-literal=q2=140 \
  --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "[OK] Lab setup complete."
echo "ServiceAccount 'report-runner' exists in namespace 'finance' with no permissions."
