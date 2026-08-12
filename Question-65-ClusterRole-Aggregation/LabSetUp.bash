#!/bin/bash
set -e

echo "Creating namespace..."
kubectl create namespace d8f3b6a1c2e4-monitoring --dry-run=client -o yaml | kubectl apply -f -

echo "[OK] Lab setup complete."
echo "   - Namespace: d8f3b6a1c2e4-monitoring"
echo "You can now build the aggregated ClusterRole structure."
