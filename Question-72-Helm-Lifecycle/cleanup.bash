#!/bin/bash
# Cleanup script for Question 72 - Helm Release Lifecycle
set -uo pipefail
echo "Cleaning up Question 72: Helm Release Lifecycle..."

helm uninstall web-lifecycle -n d8f3b6a1c2e4-helm-lab 2>/dev/null || true
kubectl delete namespace d8f3b6a1c2e4-helm-lab --ignore-not-found

echo "[OK] Question 72 cleanup complete"
echo "NOTE: the bitnami helm repo entry is left in place."
