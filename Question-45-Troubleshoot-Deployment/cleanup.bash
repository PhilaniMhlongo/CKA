#!/bin/bash
# Cleanup script for Question 45 - Troubleshoot a Broken Deployment
set -uo pipefail
echo "Cleaning up Question 45: Troubleshoot a Broken Deployment..."

kubectl delete deployment failing-app -n eda9e0ec987a-troubleshoot --ignore-not-found
kubectl delete namespace eda9e0ec987a-troubleshoot --ignore-not-found

echo "[OK] Question 45 cleanup complete"
