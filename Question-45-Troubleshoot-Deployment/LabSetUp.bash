#!/bin/bash
set -e

echo "Creating namespace..."
kubectl create namespace eda9e0ec987a-troubleshoot --dry-run=client -o yaml | kubectl apply -f -

echo "Deploying the broken 'failing-app' deployment..."
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: failing-app
  namespace: eda9e0ec987a-troubleshoot
spec:
  replicas: 2
  selector:
    matchLabels:
      app: failing-app
  template:
    metadata:
      labels:
        app: failing-app
    spec:
      containers:
        - name: nginx
          image: nginx
          ports:
            - containerPort: 8080
          resources:
            requests:
              cpu: 50m
              memory: 16Mi
            limits:
              cpu: 200m
              memory: 32Mi
          livenessProbe:
            httpGet:
              path: /
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 10
EOF

echo "[OK] Lab setup complete."
echo "   - Namespace: eda9e0ec987a-troubleshoot"
echo "   - Deployment: failing-app (intentionally broken - find and fix the three issues)"
