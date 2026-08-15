#!/bin/bash
# Cleanup script for Question 73 - etcd Snapshot Backup and Restore
set -uo pipefail
echo "Cleaning up Question 73: etcd Snapshot Backup and Restore..."

kubectl delete configmap pre-backup-marker -n d8f3b6a1c2e4-etcd-restore --ignore-not-found
kubectl delete configmap post-backup-marker -n d8f3b6a1c2e4-etcd-restore --ignore-not-found
kubectl delete namespace d8f3b6a1c2e4-etcd-restore --ignore-not-found

rm -f /opt/etcd-backup.db /opt/etcd-snapshot-status.txt

echo "[OK] Question 73 cleanup complete"
echo ""
echo "NOTE: /var/lib/etcd-restore was NOT removed and the etcd static pod was"
echo "      NOT reverted. If you completed the restore, etcd is serving from"
echo "      that directory right now - deleting it would destroy the cluster."
echo "      Revert deliberately (and only if you know the live data dir is"
echo "      still intact) by pointing the hostPath in"
echo "      /etc/kubernetes/manifests/etcd.yaml back at /var/lib/etcd."
