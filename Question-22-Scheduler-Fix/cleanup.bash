#!/bin/bash
# Cleanup script for Question 22 - Scheduler Fix
set -uo pipefail
echo "Cleaning up Question 22: Scheduler Fix..."

kubectl delete namespace triage --ignore-not-found

CKA_BACKUP_DIR="${CKA_BACKUP_DIR:-/var/tmp/.cka-backups}"

echo "NOTE: This question modifies /etc/kubernetes/manifests/kube-scheduler.yaml"

# If the manifest still points at the bogus kubeconfig path, the lab was left
# unsolved - restore the known-good manifest so scheduling works again.
if grep -q 'scheduler-wrong.conf' /etc/kubernetes/manifests/kube-scheduler.yaml 2>/dev/null; then
  if [[ -f "$CKA_BACKUP_DIR/kube-scheduler.yaml.bak" ]]; then
    echo "Manifest still points at scheduler-wrong.conf (unsolved), restoring from backup."
    sudo cp "$CKA_BACKUP_DIR/kube-scheduler.yaml.bak" /etc/kubernetes/manifests/kube-scheduler.yaml
  else
    echo "WARNING: manifest looks broken but no backup was found in $CKA_BACKUP_DIR."
    echo "Fix --kubeconfig back to /etc/kubernetes/scheduler.conf manually."
  fi
else
  echo "Manifest looks healthy - the lab was solved, leaving it alone."
fi

echo "To reset for re-practice, re-run: scripts/run-question.sh 22"
echo "[OK] Question 22 cleanup complete"
