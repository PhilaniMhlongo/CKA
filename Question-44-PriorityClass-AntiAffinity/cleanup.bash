#!/bin/bash
# Cleanup script for Question 44 - PriorityClasses + Pod Anti-Affinity
set -uo pipefail
echo "Cleaning up Question 44: PriorityClasses + Pod Anti-Affinity..."

kubectl delete pod high-priority low-priority -n eda9e0ec987a-scheduling --ignore-not-found
kubectl delete namespace eda9e0ec987a-scheduling --ignore-not-found
kubectl delete priorityclass eda9e0ec987a-high-priority eda9e0ec987a-low-priority --ignore-not-found
rm -f priority-pods.yaml

echo "[OK] Question 44 cleanup complete"
