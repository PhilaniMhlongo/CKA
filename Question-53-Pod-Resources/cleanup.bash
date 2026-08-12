#!/bin/bash
# Cleanup script for Question 53 - Pod with Resource Requests/Limits
set -uo pipefail
echo "Cleaning up Question 53: Pod with Resource Requests/Limits..."

kubectl delete pod resource-pod -n 7b43d4b5300b-monitoring --ignore-not-found
kubectl delete namespace 7b43d4b5300b-monitoring --ignore-not-found
rm -f resource-pod.yaml

echo "[OK] Question 53 cleanup complete"
