#!/bin/bash
# Cleanup script for Question 29 - Deployment + HPA
set -uo pipefail
echo "Cleaning up Question 29: Deployment + HPA..."

kubectl delete hpa --all -n eda9e0ec987a-scaling --ignore-not-found
kubectl delete deployment scaling-app -n eda9e0ec987a-scaling --ignore-not-found
kubectl delete namespace eda9e0ec987a-scaling --ignore-not-found
rm -f scaling-app.yaml

echo "[OK] Question 29 cleanup complete"
