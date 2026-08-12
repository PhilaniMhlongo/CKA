#!/bin/bash
# Cleanup script for Question 39 - LimitRange + ResourceQuota
set -uo pipefail
echo "Cleaning up Question 39: LimitRange + ResourceQuota..."

kubectl delete deployment test-limits -n eda9e0ec987a-limits --ignore-not-found
kubectl delete resourcequota compute-quota -n eda9e0ec987a-limits --ignore-not-found
kubectl delete limitrange resource-limits -n eda9e0ec987a-limits --ignore-not-found
kubectl delete namespace eda9e0ec987a-limits --ignore-not-found
rm -f limits.yaml

echo "[OK] Question 39 cleanup complete"
