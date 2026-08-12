#!/bin/bash
# Cleanup script for Question 38 - Gateway API
set -uo pipefail
echo "Cleaning up Question 38: Gateway API..."

kubectl delete httproute app-routes -n eda9e0ec987a-gateway --ignore-not-found
kubectl delete gateway main-gateway -n eda9e0ec987a-gateway --ignore-not-found
kubectl delete namespace eda9e0ec987a-gateway --ignore-not-found
kubectl delete gatewayclass example --ignore-not-found
rm -f gateway-routes.yaml

echo "[OK] Question 38 cleanup complete"
echo "NOTE: Gateway API CRDs are left in place as they are cluster-wide."
