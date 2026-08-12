#!/bin/bash
# Cleanup script for Question 50 - RBAC in default Namespace
set -uo pipefail
echo "Cleaning up Question 50: RBAC in default Namespace..."

kubectl delete rolebinding read-pods -n default --ignore-not-found
kubectl delete role pod-reader -n default --ignore-not-found
kubectl delete serviceaccount app-sa -n default --ignore-not-found
rm -f pod-reader-rbac.yaml

echo "[OK] Question 50 cleanup complete"
