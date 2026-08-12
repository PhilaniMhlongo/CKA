#!/bin/bash
# Cleanup script for Question 57 - Pod Stuck on Missing Configuration
set -uo pipefail
echo "Cleaning up Question 57: Pod Stuck on Missing Configuration..."

kubectl delete deployment config-app -n d8f3b6a1c2e4-crashloop --ignore-not-found
kubectl delete secret app-credentials -n d8f3b6a1c2e4-crashloop --ignore-not-found
kubectl delete configmap app-settings -n d8f3b6a1c2e4-crashloop --ignore-not-found
kubectl delete namespace d8f3b6a1c2e4-crashloop --ignore-not-found

echo "[OK] Question 57 cleanup complete"
