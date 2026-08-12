#!/bin/bash
# Validation script for Question 62 - Stuck Rollout
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
echo " Validating Question 62: Stuck Rollout"
echo "============================================"

check "CPU request is 100m" \
  bash -c 'kubectl get deployment stuck-app -n d8f3b6a1c2e4-rollout -o jsonpath="{.spec.template.spec.containers[0].resources.requests.cpu}" | grep -qx "100m"'

check "nodeSelector has been removed" \
  bash -c '
    kubectl get deployment stuck-app -n d8f3b6a1c2e4-rollout -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
sel = data[\"spec\"][\"template\"][\"spec\"].get(\"nodeSelector\")
sys.exit(1 if sel else 0)
"'

check "All 3 replicas are available" \
  bash -c 'AVAIL=$(kubectl get deployment stuck-app -n d8f3b6a1c2e4-rollout -o jsonpath="{.status.availableReplicas}"); [[ -n "$AVAIL" && "$AVAIL" -ge 3 ]]'

check "No stuck-app pod is Pending" \
  bash -c '! kubectl get pods -n d8f3b6a1c2e4-rollout -l app=stuck-app --no-headers 2>/dev/null | grep -q Pending'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
