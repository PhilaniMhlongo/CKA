#!/bin/bash
# Cleanup script for Question 43 - Rolling Update + Rollback
set -uo pipefail
echo "Cleaning up Question 43: Rolling Update + Rollback..."

kubectl delete deployment app-v1 -n eda9e0ec987a-upgrade --ignore-not-found
kubectl delete namespace eda9e0ec987a-upgrade --ignore-not-found
rm -f app-v1.yaml /tmp/exam/rollout-history.txt
rmdir /tmp/exam 2>/dev/null || true

echo "[OK] Question 43 cleanup complete"
