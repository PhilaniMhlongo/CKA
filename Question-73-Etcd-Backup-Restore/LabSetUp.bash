#!/bin/bash
set -e

echo "Creating namespace..."
kubectl create namespace d8f3b6a1c2e4-etcd-restore --dry-run=client -o yaml | kubectl apply -f -

echo "Creating the pre-backup marker object..."
kubectl create configmap pre-backup-marker \
  -n d8f3b6a1c2e4-etcd-restore \
  --from-literal=state=existed-before-the-backup \
  --dry-run=client -o yaml | kubectl apply -f -

echo "[OK] Lab setup complete."
echo "   - Namespace: d8f3b6a1c2e4-etcd-restore"
echo "   - ConfigMap pre-backup-marker now exists. It must survive the exercise."
echo ""
echo "NOTE: this lab REQUIRES control-plane node access (kubeadm cluster, e.g. Killercoda)."
echo "      etcdctl must be available. If it is not:"
echo "        apt-get update && apt-get install -y etcd-client"
