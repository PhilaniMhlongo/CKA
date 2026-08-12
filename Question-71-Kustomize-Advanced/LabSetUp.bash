#!/bin/bash
set -e

echo "Creating namespace..."
kubectl create namespace d8f3b6a1c2e4-prod --dry-run=client -o yaml | kubectl apply -f -

mkdir -p /tmp/exam

echo "[OK] Lab setup complete."
echo "   - Namespace: d8f3b6a1c2e4-prod"
echo "Build the Kustomize tree under /tmp/exam/kustomize-adv/."
