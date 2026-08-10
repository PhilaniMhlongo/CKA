#!/bin/bash
set -e

# Step 1: Backup current kube-scheduler manifest.
# Kept outside /root and /etc/kubernetes so that listing the obvious directories
# does not hand the learner the answer. cleanup.bash restores from here.
CKA_BACKUP_DIR="${CKA_BACKUP_DIR:-/var/tmp/.cka-backups}"
sudo mkdir -p "$CKA_BACKUP_DIR"
sudo cp /etc/kubernetes/manifests/kube-scheduler.yaml "$CKA_BACKUP_DIR/kube-scheduler.yaml.bak"

# Step 2: Simulate a bad config change - point --kubeconfig at a path that doesn't exist
sudo sed -i 's#/etc/kubernetes/scheduler.conf#/etc/kubernetes/scheduler-wrong.conf#g' /etc/kubernetes/manifests/kube-scheduler.yaml

echo "Waiting for the scheduler static pod to restart and fail..."
sleep 5

echo "Creating namespace and a pod that will now stay Pending..."
kubectl create namespace triage --dry-run=client -o yaml | kubectl apply -f -
kubectl run stuck-pod --image=nginx -n triage

echo "Checking kube-scheduler status..."
kubectl get pods -n kube-system | grep scheduler || echo "kube-scheduler pod not visible yet"

echo ""
echo "[OK] Lab setup complete. Pod 'stuck-pod' in namespace 'triage' should stay Pending."
