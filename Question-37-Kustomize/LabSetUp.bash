#!/bin/bash
set -e

echo "Creating namespace..."
kubectl create namespace eda9e0ec987a-kustomize --dry-run=client -o yaml | kubectl apply -f -

echo "[OK] Lab setup complete."
echo "   - Namespace: eda9e0ec987a-kustomize"
echo "You can now build the Kustomize structure under /tmp/exam/kustomize/."
