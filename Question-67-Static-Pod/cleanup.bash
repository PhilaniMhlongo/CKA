#!/bin/bash
# Cleanup script for Question 67 - Static Pod
set -uo pipefail
echo "Cleaning up Question 67: Static Pod..."

rm -f /etc/kubernetes/manifests/static-web.yaml
# The kubelet removes the mirror pod once the manifest is gone; nudge it anyway
sleep 5
kubectl delete pod -n default -l role=static-demo --ignore-not-found --wait=false 2>/dev/null || true

echo "[OK] Question 67 cleanup complete"
