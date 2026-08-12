#!/bin/bash
# Cleanup script for Question 71 - Advanced Kustomize
set -uo pipefail
echo "Cleaning up Question 71: Advanced Kustomize..."

kubectl delete namespace d8f3b6a1c2e4-prod --ignore-not-found
rm -rf /tmp/exam/kustomize-adv
rmdir /tmp/exam 2>/dev/null || true

echo "[OK] Question 71 cleanup complete"
