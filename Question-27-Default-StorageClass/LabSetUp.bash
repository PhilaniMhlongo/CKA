#!/bin/bash
set -e

echo "Nothing to pre-create for this question."
echo "Current StorageClasses in the cluster:"
kubectl get storageclass

echo "[OK] Lab setup complete."
echo "You can now create the StorageClass 'eda9e0ec987a-fast-local' and make it the default."
