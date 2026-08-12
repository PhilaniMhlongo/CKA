#!/bin/bash
# Cleanup script for Question 63 - Broken Sidecar Volume Sharing
set -uo pipefail
echo "Cleaning up Question 63: Broken Sidecar Volume Sharing..."

kubectl delete pod log-processor -n d8f3b6a1c2e4-sidecar --ignore-not-found
kubectl delete namespace d8f3b6a1c2e4-sidecar --ignore-not-found
rm -f log-processor-fixed.yaml

echo "[OK] Question 63 cleanup complete"
