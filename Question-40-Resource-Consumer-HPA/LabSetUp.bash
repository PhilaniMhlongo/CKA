#!/bin/bash
set -e

echo "Creating namespace..."
kubectl create namespace eda9e0ec987a-monitoring --dry-run=client -o yaml | kubectl apply -f -

echo "[OK] Lab setup complete."
echo "   - Namespace: eda9e0ec987a-monitoring"
echo "You can now create the resource-consumer deployment and its HPA."
echo "NOTE: without metrics-server the HPA will not collect metrics, but its spec is still validated."
