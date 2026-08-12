#!/bin/bash
# Cleanup script for Question 49 - Multi-Container Pod (shared emptyDir)
set -uo pipefail
echo "Cleaning up Question 49: Multi-Container Pod (shared emptyDir)..."

kubectl delete pod logger -n 7b43d4b5300b-monitoring --ignore-not-found
kubectl delete namespace 7b43d4b5300b-monitoring --ignore-not-found
rm -f logger-pod.yaml

echo "[OK] Question 49 cleanup complete"
