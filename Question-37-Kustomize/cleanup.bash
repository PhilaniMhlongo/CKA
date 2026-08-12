#!/bin/bash
# Cleanup script for Question 37 - Kustomize Base + Overlay
set -uo pipefail
echo "Cleaning up Question 37: Kustomize Base + Overlay..."

kubectl delete namespace eda9e0ec987a-kustomize --ignore-not-found
rm -rf /tmp/exam/kustomize

echo "[OK] Question 37 cleanup complete"
