#!/bin/bash
# Cleanup script for Question 33 - Headless Service + StatefulSet
set -uo pipefail
echo "Cleaning up Question 33: Headless Service + StatefulSet..."

kubectl delete statefulset web -n eda9e0ec987a-stateful --ignore-not-found
kubectl delete svc web-svc -n eda9e0ec987a-stateful --ignore-not-found
kubectl delete pvc -l app=web -n eda9e0ec987a-stateful --ignore-not-found
kubectl delete namespace eda9e0ec987a-stateful --ignore-not-found
# Only delete the StorageClass if this lab created it (it carries the lab label)
kubectl delete storageclass -l cka-lab=question-33 --ignore-not-found
rm -f web-statefulset.yaml

echo "[OK] Question 33 cleanup complete"
