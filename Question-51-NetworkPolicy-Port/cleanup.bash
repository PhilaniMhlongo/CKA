#!/bin/bash
# Cleanup script for Question 51 - NetworkPolicy with Port
set -uo pipefail
echo "Cleaning up Question 51: NetworkPolicy with Port..."

kubectl delete networkpolicy db-policy -n 7b43d4b5300b-networking --ignore-not-found
kubectl delete namespace 7b43d4b5300b-networking --ignore-not-found
rm -f db-policy.yaml

echo "[OK] Question 51 cleanup complete"
