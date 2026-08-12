#!/bin/bash
# Validation script for Question 63 - Broken Sidecar Volume Sharing
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
echo " Validating Question 63: Broken Sidecar Volume Sharing"
echo "============================================"

check "Pod 'log-processor' is Running" \
  bash -c 'kubectl get pod log-processor -n d8f3b6a1c2e4-sidecar -o jsonpath="{.status.phase}" | grep -qx Running'

check "Both containers are ready (2/2)" \
  bash -c '
    kubectl get pod log-processor -n d8f3b6a1c2e4-sidecar -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
statuses = data[\"status\"].get(\"containerStatuses\", [])
sys.exit(0 if len(statuses) == 2 and all(s.get(\"ready\") for s in statuses) else 1)
"'

check "Writer mount is no longer read-only" \
  bash -c '
    kubectl get pod log-processor -n d8f3b6a1c2e4-sidecar -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for c in data[\"spec\"][\"containers\"]:
    if c[\"name\"] == \"writer\":
        for m in c.get(\"volumeMounts\", []):
            if m[\"name\"] == \"shared\" and m.get(\"readOnly\"):
                sys.exit(1)
        sys.exit(0)
sys.exit(1)
"'

check "app.log exists and is non-empty (seen from the reader container)" \
  bash -c 'kubectl exec log-processor -n d8f3b6a1c2e4-sidecar -c reader -- sh -c "test -s /logs/app.log"'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
