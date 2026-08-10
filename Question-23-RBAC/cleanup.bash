#!/bin/bash
# Cleanup script for Question 23 - RBAC
set -uo pipefail
echo "Cleaning up Question 23: RBAC..."

kubectl delete namespace finance --ignore-not-found
kubectl delete namespace hr --ignore-not-found

# Cluster-scoped objects a learner may have created for task 3
kubectl delete clusterrole pod-lister --ignore-not-found
kubectl delete clusterrolebinding report-runner-read --ignore-not-found
kubectl delete clusterrolebinding report-runner-hr-read --ignore-not-found

echo "[OK] Question 23 cleanup complete"
