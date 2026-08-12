#!/bin/bash
set -e

echo "Creating namespace..."
kubectl create namespace eda9e0ec987a-storage-task --dry-run=client -o yaml | kubectl apply -f -

echo "Ensuring StorageClass 'standard' exists..."
if ! kubectl get storageclass standard >/dev/null 2>&1; then
  kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard
  labels:
    cka-lab: question-26
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
EOF
fi

echo "[OK] Lab setup complete."
echo "   - Namespace: eda9e0ec987a-storage-task"
echo "   - StorageClass: standard"
echo "You can now create the PVC and the pod."
