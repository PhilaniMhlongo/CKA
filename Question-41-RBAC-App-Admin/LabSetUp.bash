#!/bin/bash
set -e

echo "Creating namespace..."
kubectl create namespace eda9e0ec987a-cluster-admin --dry-run=client -o yaml | kubectl apply -f -

echo "[OK] Lab setup complete."
echo "   - Namespace: eda9e0ec987a-cluster-admin"
echo "You can now create the ServiceAccount, Role, RoleBinding and pod."
