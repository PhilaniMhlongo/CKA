#!/bin/bash
set -e

echo "Creating namespace..."
kubectl create namespace eda9e0ec987a-network --dry-run=client -o yaml | kubectl apply -f -

echo "[OK] Lab setup complete."
echo "   - Namespace: eda9e0ec987a-network"
echo "You can now create the web/api/db deployments and the three NetworkPolicies."
