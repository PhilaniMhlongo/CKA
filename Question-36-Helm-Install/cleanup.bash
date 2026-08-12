#!/bin/bash
# Cleanup script for Question 36 - Helm Install
set -uo pipefail
echo "Cleaning up Question 36: Helm Install..."

helm uninstall web-release -n eda9e0ec987a-helm-test 2>/dev/null || true
kubectl delete namespace eda9e0ec987a-helm-test --ignore-not-found

echo "[OK] Question 36 cleanup complete"
echo "NOTE: the bitnami helm repo entry is left in place."
