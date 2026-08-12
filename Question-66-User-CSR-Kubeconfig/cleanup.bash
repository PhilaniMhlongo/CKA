#!/bin/bash
# Cleanup script for Question 66 - Onboard a User via CSR + Kubeconfig
set -uo pipefail
echo "Cleaning up Question 66: Onboard a User via CSR + Kubeconfig..."

WORKDIR="${WORKDIR:-$PWD/csr-work}"

kubectl delete csr dev-user --ignore-not-found
kubectl delete rolebinding dev-user-edit -n d8f3b6a1c2e4-dev --ignore-not-found
kubectl delete namespace d8f3b6a1c2e4-dev --ignore-not-found
rm -rf "$WORKDIR"

echo "[OK] Question 66 cleanup complete"
