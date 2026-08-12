#!/bin/bash
set -e

echo "Creating namespace..."
kubectl create namespace eda9e0ec987a-dns-debug --dry-run=client -o yaml | kubectl apply -f -

echo "[OK] Lab setup complete."
echo "   - Namespace: eda9e0ec987a-dns-debug"
echo "You can now create the deployment, service and debug pod."
