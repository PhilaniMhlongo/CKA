#!/bin/bash
# Cleanup script for Question 35 - DNS Test to File
set -uo pipefail
echo "Cleaning up Question 35: DNS Test to File..."

kubectl delete pod dns-tester -n eda9e0ec987a-dns-config --ignore-not-found
kubectl delete svc dns-svc -n eda9e0ec987a-dns-config --ignore-not-found
kubectl delete deployment dns-app -n eda9e0ec987a-dns-config --ignore-not-found
kubectl delete namespace eda9e0ec987a-dns-config --ignore-not-found
rm -f dns-config.yaml

echo "[OK] Question 35 cleanup complete"
