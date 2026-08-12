#!/bin/bash
set -e

echo "Creating namespace..."
kubectl create namespace d8f3b6a1c2e4-crashloop --dry-run=client -o yaml | kubectl apply -f -

echo "Deploying the (stuck) application..."
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: config-app
  namespace: d8f3b6a1c2e4-crashloop
spec:
  replicas: 1
  selector:
    matchLabels:
      app: config-app
  template:
    metadata:
      labels:
        app: config-app
    spec:
      initContainers:
        - name: init-check
          image: busybox:1.36
          command: ["sh", "-c", "echo init ok, DB_HOST=\$DB_HOST"]
          env:
            - name: DB_HOST
              valueFrom:
                configMapKeyRef:
                  name: app-settings
                  key: db_host
      containers:
        - name: app
          image: busybox:1.36
          command: ["sh", "-c", "echo app started with USER=\$DB_USER; sleep 3600"]
          envFrom:
            - secretRef:
                name: app-credentials
EOF

echo "[OK] Lab setup complete."
echo "   - Namespace: d8f3b6a1c2e4-crashloop"
echo "   - Deployment config-app cannot start. Work out why and fix it"
echo "     WITHOUT modifying the deployment."
