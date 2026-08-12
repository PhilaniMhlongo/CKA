#!/bin/bash
# Cleanup script for Question 58 - NetworkPolicy Connectivity Debug
set -uo pipefail
echo "Cleaning up Question 58: NetworkPolicy Connectivity Debug..."

kubectl delete networkpolicy --all -n d8f3b6a1c2e4-netpol-debug --ignore-not-found
kubectl delete pod client -n d8f3b6a1c2e4-netpol-debug --ignore-not-found
kubectl delete svc web-svc -n d8f3b6a1c2e4-netpol-debug --ignore-not-found
kubectl delete deployment web -n d8f3b6a1c2e4-netpol-debug --ignore-not-found
kubectl delete namespace d8f3b6a1c2e4-netpol-debug --ignore-not-found
rm -f netpol-allow.yaml

echo "[OK] Question 58 cleanup complete"
