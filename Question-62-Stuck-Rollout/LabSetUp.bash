#!/bin/bash
set -e

echo "Creating namespace..."
kubectl create namespace d8f3b6a1c2e4-rollout --dry-run=client -o yaml | kubectl apply -f -

echo "Deploying the (unschedulable) application..."
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: stuck-app
  namespace: d8f3b6a1c2e4-rollout
spec:
  replicas: 3
  selector:
    matchLabels:
      app: stuck-app
  template:
    metadata:
      labels:
        app: stuck-app
    spec:
      nodeSelector:
        disk: superfast
      containers:
        - name: nginx
          image: nginx
          resources:
            requests:
              cpu: "4"
              memory: 64Mi
EOF

echo "[OK] Lab setup complete."
echo "   - Namespace: d8f3b6a1c2e4-rollout"
echo "   - All 3 pods of 'stuck-app' are Pending. Find out why (two reasons)."
