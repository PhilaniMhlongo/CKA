#!/bin/bash
# Validation script for Question 73 - etcd Snapshot Backup and Restore
set -uo pipefail

PASS=0
FAIL=0
TOTAL=0

check() {
  local description="$1"
  shift
  TOTAL=$((TOTAL + 1))
  if "$@" >/dev/null 2>&1; then
    echo "  PASS: $description"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $description"
    FAIL=$((FAIL + 1))
  fi
}

echo "============================================"
echo " Validating Question 73: etcd Snapshot Backup and Restore"
echo "============================================"

check "Snapshot file /opt/etcd-backup.db exists and is not empty" \
  bash -c '[[ -s /opt/etcd-backup.db ]]'

check "Snapshot is a valid etcd snapshot (etcdctl snapshot status)" \
  bash -c 'ETCDCTL_API=3 etcdctl snapshot status /opt/etcd-backup.db --write-out=json'

check "Snapshot status output saved to /opt/etcd-snapshot-status.txt" \
  bash -c '[[ -s /opt/etcd-snapshot-status.txt ]]'

check "Restored data directory /var/lib/etcd-restore/member exists" \
  bash -c '[[ -d /var/lib/etcd-restore/member ]]'

check "etcd static pod hostPath points at the restored data directory" \
  bash -c 'grep -qE "path:[[:space:]]*/var/lib/etcd-restore/?$" /etc/kubernetes/manifests/etcd.yaml'

check "ConfigMap pre-backup-marker was brought back by the restore" \
  kubectl get configmap pre-backup-marker -n d8f3b6a1c2e4-etcd-restore

# Confirm the API server is actually reachable first, so an unreachable
# cluster cannot make this negative check pass by accident.
check "ConfigMap post-backup-marker is gone (it was never in the snapshot)" \
  bash -c 'kubectl get namespace d8f3b6a1c2e4-etcd-restore \
           && ! kubectl get configmap post-backup-marker -n d8f3b6a1c2e4-etcd-restore'

check "API server is serving and every node is Ready" \
  bash -c '
    kubectl get nodes -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
if not data[\"items\"]:
    sys.exit(1)
for node in data[\"items\"]:
    ready = [c for c in node[\"status\"][\"conditions\"] if c[\"type\"] == \"Ready\"]
    if not ready or ready[0][\"status\"] != \"True\":
        sys.exit(1)
sys.exit(0)
"'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
