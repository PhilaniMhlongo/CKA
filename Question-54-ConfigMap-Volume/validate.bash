#!/bin/bash
# Validation script for Question 54 - ConfigMap as Volume
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
echo " Validating Question 54: ConfigMap as Volume"
echo "============================================"

check "ConfigMap 'app-config' has APP_COLOR=blue" \
  bash -c 'kubectl get configmap app-config -o jsonpath="{.data.APP_COLOR}" | grep -qx blue'

check "Pod 'config-pod' mounts the ConfigMap at /etc/config" \
  bash -c '
    kubectl get pod config-pod -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
spec = data[\"spec\"]
cmvols = {v[\"name\"] for v in spec.get(\"volumes\", []) if v.get(\"configMap\", {}).get(\"name\") == \"app-config\"}
for c in spec[\"containers\"]:
    for m in c.get(\"volumeMounts\", []):
        if m[\"name\"] in cmvols and m[\"mountPath\"] == \"/etc/config\":
            sys.exit(0)
sys.exit(1)
"'

check "APP_COLOR file in the pod contains 'blue'" \
  bash -c 'kubectl exec config-pod -- cat /etc/config/APP_COLOR 2>/dev/null | grep -q blue'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
