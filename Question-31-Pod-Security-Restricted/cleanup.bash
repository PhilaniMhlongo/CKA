#!/bin/bash
# Cleanup script for Question 31 - Pod Security (restricted)
set -uo pipefail
echo "Cleaning up Question 31: Pod Security (restricted)..."

kubectl delete pod secure-pod -n eda9e0ec987a-security --ignore-not-found
kubectl delete namespace eda9e0ec987a-security --ignore-not-found
rm -f secure-pod.yaml

echo "[OK] Question 31 cleanup complete"
