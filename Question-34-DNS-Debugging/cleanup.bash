#!/bin/bash
# Cleanup script for Question 34 - DNS Debugging (dnsConfig)
set -uo pipefail
echo "Cleaning up Question 34: DNS Debugging (dnsConfig)..."

kubectl delete pod dns-test -n eda9e0ec987a-dns-debug --ignore-not-found
kubectl delete svc web-svc -n eda9e0ec987a-dns-debug --ignore-not-found
kubectl delete deployment web-app -n eda9e0ec987a-dns-debug --ignore-not-found
kubectl delete namespace eda9e0ec987a-dns-debug --ignore-not-found
rm -f dns-debug.yaml

echo "[OK] Question 34 cleanup complete"
