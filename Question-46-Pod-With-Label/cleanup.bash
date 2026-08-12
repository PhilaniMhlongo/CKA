#!/bin/bash
# Cleanup script for Question 46 - Simple Pod with Label
set -uo pipefail
echo "Cleaning up Question 46: Simple Pod with Label..."

kubectl delete pod nginx-pod -n 7b43d4b5300b-app-team1 --ignore-not-found
kubectl delete namespace 7b43d4b5300b-app-team1 --ignore-not-found

echo "[OK] Question 46 cleanup complete"
