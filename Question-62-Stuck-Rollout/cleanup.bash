#!/bin/bash
# Cleanup script for Question 62 - Stuck Rollout
set -uo pipefail
echo "Cleaning up Question 62: Stuck Rollout..."

kubectl delete deployment stuck-app -n d8f3b6a1c2e4-rollout --ignore-not-found
kubectl delete namespace d8f3b6a1c2e4-rollout --ignore-not-found

echo "[OK] Question 62 cleanup complete"
