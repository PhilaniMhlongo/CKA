#!/bin/bash
# Cleanup script for Question 54 - ConfigMap as Volume
set -uo pipefail
echo "Cleaning up Question 54: ConfigMap as Volume..."

kubectl delete pod config-pod --ignore-not-found
kubectl delete configmap app-config --ignore-not-found
rm -f config-pod.yaml

echo "[OK] Question 54 cleanup complete"
