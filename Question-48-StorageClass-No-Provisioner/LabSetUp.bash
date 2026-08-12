#!/bin/bash
set -e

echo "Creating namespace..."
kubectl create namespace 7b43d4b5300b-storage --dry-run=client -o yaml | kubectl apply -f -

echo "[OK] Lab setup complete."
echo "   - Namespace: 7b43d4b5300b-storage"
echo "You can now create the StorageClass and the PVC."
