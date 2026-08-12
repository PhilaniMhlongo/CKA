#!/bin/bash
set -e

echo "Creating namespace..."
kubectl create namespace eda9e0ec987a-security --dry-run=client -o yaml | kubectl apply -f -

echo "[OK] Lab setup complete."
echo "   - Namespace: eda9e0ec987a-security (not yet labelled)"
echo "You can now label the namespace and create the compliant pod."
