#!/bin/bash
# Cleanup script for Question 42 - Tiered NetworkPolicies
set -uo pipefail
echo "Cleaning up Question 42: Tiered NetworkPolicies..."

kubectl delete networkpolicy web-policy api-policy db-policy -n eda9e0ec987a-network --ignore-not-found
kubectl delete deployment web api db -n eda9e0ec987a-network --ignore-not-found
kubectl delete namespace eda9e0ec987a-network --ignore-not-found
rm -f tiered-policies.yaml

echo "[OK] Question 42 cleanup complete"
