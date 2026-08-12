#!/bin/bash
# Cleanup script for Question 65 - ClusterRole Aggregation
set -uo pipefail
echo "Cleaning up Question 65: ClusterRole Aggregation..."

kubectl delete clusterrolebinding monitoring-admin-binding --ignore-not-found
kubectl delete clusterrole monitoring-admin monitoring-pods monitoring-nodes --ignore-not-found
kubectl delete serviceaccount monitor-sa -n d8f3b6a1c2e4-monitoring --ignore-not-found
kubectl delete namespace d8f3b6a1c2e4-monitoring --ignore-not-found
rm -f monitoring-rbac.yaml

echo "[OK] Question 65 cleanup complete"
