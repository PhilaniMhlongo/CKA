#!/bin/bash
# Cleanup script for Question 61 - PVC Binding Failure
set -uo pipefail
echo "Cleaning up Question 61: PVC Binding Failure..."

kubectl delete pod data-consumer -n d8f3b6a1c2e4-storage-fix --ignore-not-found
kubectl delete pvc data-claim -n d8f3b6a1c2e4-storage-fix --ignore-not-found
kubectl delete namespace d8f3b6a1c2e4-storage-fix --ignore-not-found
kubectl delete pv d8f3b6a1c2e4-data-pv --ignore-not-found
rm -f q61-fixed.yaml

echo "[OK] Question 61 cleanup complete"
