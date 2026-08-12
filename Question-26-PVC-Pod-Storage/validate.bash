#!/bin/bash
# Validation script for Question 26 - PVC + Pod (Storage)
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
echo " Validating Question 26: PVC + Pod (Storage)"
echo "============================================"

check "Namespace 'eda9e0ec987a-storage-task' exists" \
  kubectl get namespace eda9e0ec987a-storage-task

check "PVC 'data-pvc' exists" \
  kubectl get pvc data-pvc -n eda9e0ec987a-storage-task

check "PVC uses StorageClass 'standard'" \
  bash -c 'kubectl get pvc data-pvc -n eda9e0ec987a-storage-task -o jsonpath="{.spec.storageClassName}" | grep -qx standard'

check "PVC requests 2Gi with ReadWriteOnce" \
  bash -c 'kubectl get pvc data-pvc -n eda9e0ec987a-storage-task -o jsonpath="{.spec.resources.requests.storage}|{.spec.accessModes[0]}" | grep -qx "2Gi|ReadWriteOnce"'

check "Pod 'data-pod' exists and uses nginx image" \
  bash -c 'kubectl get pod data-pod -n eda9e0ec987a-storage-task -o jsonpath="{.spec.containers[0].image}" | grep -q nginx'

check "Pod mounts PVC 'data-pvc' at /usr/share/nginx/html" \
  bash -c '
    kubectl get pod data-pod -n eda9e0ec987a-storage-task -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
spec = data[\"spec\"]
vols = {v[\"name\"]: v for v in spec.get(\"volumes\", [])}
for c in spec[\"containers\"]:
    for m in c.get(\"volumeMounts\", []):
        if m[\"mountPath\"] == \"/usr/share/nginx/html\":
            v = vols.get(m[\"name\"], {})
            pvc = v.get(\"persistentVolumeClaim\", {})
            if pvc.get(\"claimName\") == \"data-pvc\":
                sys.exit(0)
sys.exit(1)
"'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
