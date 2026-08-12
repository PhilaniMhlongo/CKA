#!/bin/bash
# Cleanup script for Question 28 - Manual PV / PVC / Pod
set -uo pipefail
echo "Cleaning up Question 28: Manual PV / PVC / Pod..."

kubectl delete pod manual-pod -n eda9e0ec987a-manual-storage --ignore-not-found
kubectl delete pvc manual-pvc -n eda9e0ec987a-manual-storage --ignore-not-found
kubectl delete namespace eda9e0ec987a-manual-storage --ignore-not-found
kubectl delete pv eda9e0ec987a-manual-pv --ignore-not-found
rm -f manual-storage.yaml

echo "[OK] Question 28 cleanup complete"
echo "NOTE: /mnt/data on the node is not removed automatically."
