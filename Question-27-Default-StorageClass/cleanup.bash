#!/bin/bash
# Cleanup script for Question 27 - Default StorageClass
set -uo pipefail
echo "Cleaning up Question 27: Default StorageClass..."

kubectl delete storageclass eda9e0ec987a-fast-local --ignore-not-found
rm -f fast-local-sc.yaml

echo "[OK] Question 27 cleanup complete"
