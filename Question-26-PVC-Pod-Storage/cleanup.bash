#!/bin/bash
# Cleanup script for Question 26 - PVC + Pod (Storage)
set -uo pipefail
echo "Cleaning up Question 26: PVC + Pod (Storage)..."

kubectl delete pod data-pod -n eda9e0ec987a-storage-task --ignore-not-found
kubectl delete pvc data-pvc -n eda9e0ec987a-storage-task --ignore-not-found
kubectl delete namespace eda9e0ec987a-storage-task --ignore-not-found
# Only delete the StorageClass if this lab created it (it carries the lab label)
kubectl delete storageclass -l cka-lab=question-26 --ignore-not-found
rm -f pvc-pod.yaml

echo "[OK] Question 26 cleanup complete"
