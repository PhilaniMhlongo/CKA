#!/bin/bash
# Cleanup script for Question 20 - Kubelet Fix
set -uo pipefail
echo "Cleaning up Question 20: Kubelet Fix..."

CKA_BACKUP_DIR="${CKA_BACKUP_DIR:-/var/tmp/.cka-backups}"

echo "NOTE: This question removes /etc/kubernetes/kubelet.conf on the local node."
if [[ -f /etc/kubernetes/kubelet.conf ]]; then
  echo "kubelet.conf is present - the lab was solved, leaving it alone."
elif [[ -f "$CKA_BACKUP_DIR/kubelet.conf.bak" ]]; then
  echo "kubelet.conf is still missing (unsolved), restoring from backup."
  sudo cp "$CKA_BACKUP_DIR/kubelet.conf.bak" /etc/kubernetes/kubelet.conf
  sudo systemctl restart kubelet
else
  echo "WARNING: kubelet.conf is missing and no backup was found in $CKA_BACKUP_DIR."
  echo "Regenerate it with: sudo kubeadm init phase kubeconfig kubelet"
fi

echo "To re-run the lab from scratch, use: scripts/run-question.sh 20"
echo "[OK] Question 20 cleanup complete (node left healthy)"
