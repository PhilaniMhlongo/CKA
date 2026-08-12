#!/bin/bash
# Cleanup script for Question 32 - Taints & Tolerations
set -uo pipefail
echo "Cleaning up Question 32: Taints & Tolerations..."

kubectl delete deployment toleration-deploy normal-deploy -n eda9e0ec987a-scheduling --ignore-not-found
kubectl delete namespace eda9e0ec987a-scheduling --ignore-not-found
kubectl taint nodes --all special-workload- >/dev/null 2>&1 || true
rm -f taint-toleration.yaml /tmp/q32-pods.json

echo "[OK] Question 32 cleanup complete"
