#!/bin/bash
set -e

echo "Creating namespace..."
kubectl create namespace eda9e0ec987a-manual-storage --dry-run=client -o yaml | kubectl apply -f -

echo "[OK] Lab setup complete."
echo "   - Namespace: eda9e0ec987a-manual-storage"
echo "You can now create the PV, PVC and pod."
