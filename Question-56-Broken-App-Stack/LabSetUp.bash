#!/bin/bash
set -e

echo "Creating namespace..."
kubectl create namespace d8f3b6a1c2e4-broken-stack --dry-run=client -o yaml | kubectl apply -f -

echo "Deploying the (broken) application stack..."
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-stack
  namespace: d8f3b6a1c2e4-broken-stack
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-stack
  template:
    metadata:
      labels:
        app: web-stack
    spec:
      containers:
        - name: nginx
          image: nginx:1.99-fake
          ports:
            - containerPort: 80
          readinessProbe:
            httpGet:
              path: /healthz
              port: 80
            initialDelaySeconds: 3
            periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: web-stack-svc
  namespace: d8f3b6a1c2e4-broken-stack
spec:
  selector:
    app: webstack
  ports:
    - port: 80
      targetPort: 8080
EOF

echo "[OK] Lab setup complete."
echo "   - Namespace: d8f3b6a1c2e4-broken-stack"
echo "   - The stack is broken in FOUR places. Find and fix them all."
