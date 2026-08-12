#!/bin/bash
# Cleanup script for Question 52 - Deployment + NodePort Service
set -uo pipefail
echo "Cleaning up Question 52: Deployment + NodePort Service..."

kubectl delete svc web-service --ignore-not-found
kubectl delete deployment web-app --ignore-not-found
rm -f web-app.yaml

echo "[OK] Question 52 cleanup complete"
