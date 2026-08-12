#!/bin/bash
set -e

echo "Creating namespace..."
kubectl create namespace d8f3b6a1c2e4-pdb-drain --dry-run=client -o yaml | kubectl apply -f -

echo "Deploying the app and a (too strict) PodDisruptionBudget..."
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pdb-app
  namespace: d8f3b6a1c2e4-pdb-drain
spec:
  replicas: 3
  selector:
    matchLabels:
      app: pdb-app
  template:
    metadata:
      labels:
        app: pdb-app
    spec:
      containers:
        - name: nginx
          image: nginx
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: pdb-app-guard
  namespace: d8f3b6a1c2e4-pdb-drain
spec:
  maxUnavailable: 0
  selector:
    matchLabels:
      app: pdb-app
EOF

echo "[OK] Lab setup complete."
echo "   - Namespace: d8f3b6a1c2e4-pdb-drain"
echo "   - Try draining a node that runs pdb-app pods: it will hang. That is the lab."
echo "NOTE: this lab needs at least 2 schedulable nodes to fully pass validation."
