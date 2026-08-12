#!/bin/bash
# Validation script for Question 28 - Manual PV / PVC / Pod
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
echo " Validating Question 28: Manual PV / PVC / Pod"
echo "============================================"

check "PV 'eda9e0ec987a-manual-pv' has 1Gi, ReadWriteOnce and hostPath /mnt/data" \
  bash -c 'kubectl get pv eda9e0ec987a-manual-pv -o jsonpath="{.spec.capacity.storage}|{.spec.accessModes[0]}|{.spec.hostPath.path}" | grep -qx "1Gi|ReadWriteOnce|/mnt/data"'

check "PV has nodeAffinity on kubernetes.io/hostname" \
  bash -c 'kubectl get pv eda9e0ec987a-manual-pv -o jsonpath="{.spec.nodeAffinity.required}" | grep -q "kubernetes.io/hostname"'

check "PVC 'manual-pvc' uses empty storageClassName and requests 1Gi" \
  bash -c '
    kubectl get pvc manual-pvc -n eda9e0ec987a-manual-storage -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
spec = data[\"spec\"]
if spec.get(\"storageClassName\", \"\") == \"\" and spec[\"resources\"][\"requests\"][\"storage\"] == \"1Gi\":
    sys.exit(0)
sys.exit(1)
"'

check "PVC is Bound to the PV" \
  bash -c 'kubectl get pvc manual-pvc -n eda9e0ec987a-manual-storage -o jsonpath="{.status.phase}" | grep -qx Bound'

check "Pod 'manual-pod' exists and uses busybox" \
  bash -c 'kubectl get pod manual-pod -n eda9e0ec987a-manual-storage -o jsonpath="{.spec.containers[0].image}" | grep -q busybox'

check "Pod mounts PVC 'manual-pvc' at /data" \
  bash -c '
    kubectl get pod manual-pod -n eda9e0ec987a-manual-storage -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
spec = data[\"spec\"]
vols = {v[\"name\"]: v for v in spec.get(\"volumes\", [])}
for c in spec[\"containers\"]:
    for m in c.get(\"volumeMounts\", []):
        if m[\"mountPath\"] == \"/data\":
            pvc = vols.get(m[\"name\"], {}).get(\"persistentVolumeClaim\", {})
            if pvc.get(\"claimName\") == \"manual-pvc\":
                sys.exit(0)
sys.exit(1)
"'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
