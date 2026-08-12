#!/bin/bash
# Cleanup script for Question 59 - RBAC Debugging
set -uo pipefail
echo "Cleaning up Question 59: RBAC Debugging..."

kubectl delete rolebinding inspect-pods -n d8f3b6a1c2e4-rbac-debug --ignore-not-found
kubectl delete role pod-inspector -n d8f3b6a1c2e4-rbac-debug --ignore-not-found
kubectl delete serviceaccount reporting-sa -n d8f3b6a1c2e4-rbac-debug --ignore-not-found
kubectl delete namespace d8f3b6a1c2e4-rbac-debug --ignore-not-found

echo "[OK] Question 59 cleanup complete"
