#!/bin/bash
# Validation script for Question 72 - Helm Release Lifecycle
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

NS=d8f3b6a1c2e4-helm-lab

echo "============================================"
echo " Validating Question 72: Helm Release Lifecycle"
echo "============================================"

check "Release 'web-lifecycle' is deployed" \
  bash -c 'helm list -n "'"$NS"'" 2>/dev/null | grep web-lifecycle | grep -q deployed'

check "Release history has at least 3 revisions" \
  bash -c 'REVS=$(helm history web-lifecycle -n "'"$NS"'" 2>/dev/null | grep -c "^[0-9]"); [[ "$REVS" -ge 3 ]]'

check "Latest revision is a rollback to revision 1" \
  bash -c 'helm history web-lifecycle -n "'"$NS"'" 2>/dev/null | tail -1 | grep -qi "rollback to 1"'

check "Deployment is back to 1 replica" \
  bash -c '
    kubectl get deployment -n "'"$NS"'" -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for dep in data[\"items\"]:
    if dep[\"spec\"].get(\"replicas\") == 1:
        sys.exit(0)
sys.exit(1)
"'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
