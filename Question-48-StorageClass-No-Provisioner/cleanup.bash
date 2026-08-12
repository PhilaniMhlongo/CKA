#!/bin/bash
# Cleanup script for Question 48 - StorageClass + PVC (no-provisioner)
set -uo pipefail
echo "Cleaning up Question 48: StorageClass + PVC (no-provisioner)..."

kubectl delete pvc data-pvc -n 7b43d4b5300b-storage --ignore-not-found
kubectl delete namespace 7b43d4b5300b-storage --ignore-not-found
kubectl delete storageclass 7b43d4b5300b-fast-storage --ignore-not-found
rm -f fast-storage.yaml

echo "[OK] Question 48 cleanup complete"
