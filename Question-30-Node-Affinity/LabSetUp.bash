#!/bin/bash
set -e

echo "Creating namespace..."
kubectl create namespace eda9e0ec987a-scheduling --dry-run=client -o yaml | kubectl apply -f -

echo "Available nodes:"
kubectl get nodes

echo "[OK] Lab setup complete."
echo "   - Namespace: eda9e0ec987a-scheduling"
echo "You can now label a worker node and create the deployment."
