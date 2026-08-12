#!/bin/bash
set -e

echo "Creating namespace..."
kubectl create namespace eda9e0ec987a-stateful --dry-run=client -o yaml | kubectl apply -f -

echo "Ensuring StorageClass 'cold' exists..."
if ! kubectl get storageclass cold >/dev/null 2>&1; then
  kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: cold
  labels:
    cka-lab: question-33
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF
fi

echo "[OK] Lab setup complete."
echo "   - Namespace: eda9e0ec987a-stateful"
echo "   - StorageClass: cold"
echo "You can now create the headless service and the StatefulSet."
