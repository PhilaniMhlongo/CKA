#!/bin/bash
# Cleanup script for Question 40 - Resource Consumer + HPA
set -uo pipefail
echo "Cleaning up Question 40: Resource Consumer + HPA..."

kubectl delete hpa --all -n eda9e0ec987a-monitoring --ignore-not-found
kubectl delete deployment resource-consumer -n eda9e0ec987a-monitoring --ignore-not-found
kubectl delete namespace eda9e0ec987a-monitoring --ignore-not-found
rm -f resource-consumer.yaml

echo "[OK] Question 40 cleanup complete"
