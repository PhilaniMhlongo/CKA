#!/bin/bash
set -e

echo "Creating namespace..."
kubectl create namespace eda9e0ec987a-upgrade --dry-run=client -o yaml | kubectl apply -f -

echo "[OK] Lab setup complete."
echo "   - Namespace: eda9e0ec987a-upgrade"
echo "You can now create the deployment, update it, save the history and roll back."
