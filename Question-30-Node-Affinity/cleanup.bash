#!/bin/bash
# Cleanup script for Question 30 - Node Affinity
set -uo pipefail
echo "Cleaning up Question 30: Node Affinity..."

kubectl delete deployment app-scheduling -n eda9e0ec987a-scheduling --ignore-not-found
kubectl delete namespace eda9e0ec987a-scheduling --ignore-not-found
kubectl label nodes --all disk- >/dev/null 2>&1 || true
rm -f app-scheduling.yaml

echo "[OK] Question 30 cleanup complete"
