#!/bin/bash
# Validation script for Question 49 - Multi-Container Pod (shared emptyDir)
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
echo " Validating Question 49: Multi-Container Pod (shared emptyDir)"
echo "============================================"

check "Pod 'logger' has a busybox and a fluentd container" \
  bash -c '
    kubectl get pod logger -n 7b43d4b5300b-monitoring -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
images = [c[\"image\"] for c in data[\"spec\"][\"containers\"]]
if any(\"busybox\" in i for i in images) and any(\"fluentd\" in i for i in images):
    sys.exit(0)
sys.exit(1)
"'

check "Both containers share an emptyDir volume at /var/log" \
  bash -c '
    kubectl get pod logger -n 7b43d4b5300b-monitoring -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
spec = data[\"spec\"]
empty = {v[\"name\"] for v in spec.get(\"volumes\", []) if \"emptyDir\" in v}
count = 0
for c in spec[\"containers\"]:
    for m in c.get(\"volumeMounts\", []):
        if m[\"name\"] in empty and m[\"mountPath\"] == \"/var/log\":
            count += 1
            break
sys.exit(0 if count >= 2 else 1)
"'

check "Pod is Running" \
  bash -c 'kubectl get pod logger -n 7b43d4b5300b-monitoring -o jsonpath="{.status.phase}" | grep -qx Running'

check "Log file /var/log/app.log has content (visible from fluentd container)" \
  bash -c 'kubectl exec logger -n 7b43d4b5300b-monitoring -c fluentd -- sh -c "test -s /var/log/app.log"'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
