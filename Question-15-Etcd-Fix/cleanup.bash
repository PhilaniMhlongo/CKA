#!/bin/bash
# Cleanup script for Question 15 - Etcd Fix
set -uo pipefail
echo "Cleaning up Question 15: Etcd Fix..."

CKA_BACKUP_DIR="${CKA_BACKUP_DIR:-/var/tmp/.cka-backups}"

echo "NOTE: This question modifies /etc/kubernetes/manifests/kube-apiserver.yaml"

# If the apiserver is still pointing at the etcd peer port, the lab was left
# unsolved - restore the known-good manifest so the cluster is usable again.
if grep -q ':2380' /etc/kubernetes/manifests/kube-apiserver.yaml 2>/dev/null; then
  if [[ -f "$CKA_BACKUP_DIR/kube-apiserver.yaml.bak" ]]; then
    echo "Manifest still points at the etcd peer port (unsolved), restoring from backup."
    sudo cp "$CKA_BACKUP_DIR/kube-apiserver.yaml.bak" /etc/kubernetes/manifests/kube-apiserver.yaml
    echo "Waiting for the kube-apiserver static pod to come back..."
    for _ in $(seq 1 30); do
      kubectl get nodes >/dev/null 2>&1 && break
      sleep 5
    done
  else
    echo "WARNING: manifest looks broken but no backup was found in $CKA_BACKUP_DIR."
    echo "Fix --etcd-servers back to port 2379 manually."
  fi
else
  echo "Manifest looks healthy - the lab was solved, leaving it alone."
fi

echo "To reset for re-practice, re-run: scripts/run-question.sh 15"
echo "[OK] Question 15 cleanup complete"
