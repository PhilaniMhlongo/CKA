#!/bin/bash
# Cleanup script for Question 56 - Broken App Stack
set -uo pipefail
echo "Cleaning up Question 56: Broken App Stack..."

kubectl delete svc web-stack-svc -n d8f3b6a1c2e4-broken-stack --ignore-not-found
kubectl delete deployment web-stack -n d8f3b6a1c2e4-broken-stack --ignore-not-found
kubectl delete namespace d8f3b6a1c2e4-broken-stack --ignore-not-found

echo "[OK] Question 56 cleanup complete"
