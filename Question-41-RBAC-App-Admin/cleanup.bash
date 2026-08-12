#!/bin/bash
# Cleanup script for Question 41 - RBAC (Role / RoleBinding / SA)
set -uo pipefail
echo "Cleaning up Question 41: RBAC (Role / RoleBinding / SA)..."

kubectl delete pod admin-pod -n eda9e0ec987a-cluster-admin --ignore-not-found
kubectl delete rolebinding app-admin -n eda9e0ec987a-cluster-admin --ignore-not-found
kubectl delete role app-admin -n eda9e0ec987a-cluster-admin --ignore-not-found
kubectl delete serviceaccount app-admin -n eda9e0ec987a-cluster-admin --ignore-not-found
kubectl delete namespace eda9e0ec987a-cluster-admin --ignore-not-found
rm -f app-admin-rbac.yaml

echo "[OK] Question 41 cleanup complete"
