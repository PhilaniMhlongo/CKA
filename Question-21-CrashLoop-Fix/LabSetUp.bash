#!/bin/bash
set -e

echo "Creating namespace..."
kubectl create namespace shopping --dry-run=client -o yaml | kubectl apply -f -

echo "Deploying a broken webapp (bad container command)..."
kubectl apply -n shopping -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  namespace: shopping
spec:
  replicas: 2
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: webapp
        image: nginx
        command: ["ngin"]
EOF

echo "[OK] Lab setup complete. The webapp deployment in namespace 'shopping' will CrashLoopBackOff."
