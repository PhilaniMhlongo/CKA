#!/bin/bash
set -e

echo "Creating namespace..."
kubectl create namespace eda9e0ec987a-scaling --dry-run=client -o yaml | kubectl apply -f -

echo "[OK] Lab setup complete."
echo "   - Namespace: eda9e0ec987a-scaling"
echo "You can now create the deployment and the HPA."
echo "NOTE: without metrics-server the HPA will not collect metrics, but its spec is still validated."
