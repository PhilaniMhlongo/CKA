#!/bin/bash
# Cleanup script for Question 47 - DaemonSet with hostPath
set -uo pipefail
echo "Cleaning up Question 47: DaemonSet with hostPath..."

kubectl delete daemonset log-collector -n 7b43d4b5300b-logging --ignore-not-found
kubectl delete namespace 7b43d4b5300b-logging --ignore-not-found
rm -f log-collector.yaml

echo "[OK] Question 47 cleanup complete"
