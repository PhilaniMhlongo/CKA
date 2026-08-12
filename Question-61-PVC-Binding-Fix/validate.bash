#!/bin/bash
# Validation script for Question 61 - PVC Binding Failure
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
echo " Validating Question 61: PVC Binding Failure"
echo "============================================"

check "PV 'd8f3b6a1c2e4-data-pv' was not modified (1Gi, RWO, class manual)" \
  bash -c 'kubectl get pv d8f3b6a1c2e4-data-pv -o jsonpath="{.spec.capacity.storage}|{.spec.accessModes[0]}|{.spec.storageClassName}" | grep -qx "1Gi|ReadWriteOnce|manual"'

check "PVC 'data-claim' matches the PV (manual / RWO / 1Gi)" \
  bash -c 'kubectl get pvc data-claim -n d8f3b6a1c2e4-storage-fix -o jsonpath="{.spec.storageClassName}|{.spec.accessModes[0]}|{.spec.resources.requests.storage}" | grep -qx "manual|ReadWriteOnce|1Gi"'

check "PVC is Bound" \
  bash -c 'kubectl get pvc data-claim -n d8f3b6a1c2e4-storage-fix -o jsonpath="{.status.phase}" | grep -qx Bound'

check "PV is Bound to this claim" \
  bash -c 'kubectl get pv d8f3b6a1c2e4-data-pv -o jsonpath="{.spec.claimRef.name}|{.status.phase}" | grep -qx "data-claim|Bound"'

check "Pod 'data-consumer' is Running with the claim mounted at /data" \
  bash -c '
    kubectl get pod data-consumer -n d8f3b6a1c2e4-storage-fix -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
if data[\"status\"].get(\"phase\") != \"Running\":
    sys.exit(1)
spec = data[\"spec\"]
vols = {v[\"name\"]: v for v in spec.get(\"volumes\", [])}
for c in spec[\"containers\"]:
    for m in c.get(\"volumeMounts\", []):
        if m[\"mountPath\"] == \"/data\":
            pvc = vols.get(m[\"name\"], {}).get(\"persistentVolumeClaim\", {})
            if pvc.get(\"claimName\") == \"data-claim\":
                sys.exit(0)
sys.exit(1)
"'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
