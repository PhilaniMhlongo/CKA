#!/bin/bash
# Validation script for Question 36 - Helm Install
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
echo " Validating Question 36: Helm Install"
echo "============================================"

check "Release 'web-release' is deployed in eda9e0ec987a-helm-test" \
  bash -c 'helm list -n eda9e0ec987a-helm-test 2>/dev/null | grep web-release | grep -q deployed'

check "A NodePort service exists in the namespace" \
  bash -c '
    kubectl get svc -n eda9e0ec987a-helm-test -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for svc in data[\"items\"]:
    if svc[\"spec\"].get(\"type\") == \"NodePort\":
        sys.exit(0)
sys.exit(1)
"'

check "The release deployment has 2 replicas" \
  bash -c '
    kubectl get deployment -n eda9e0ec987a-helm-test -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for dep in data[\"items\"]:
    if dep[\"spec\"].get(\"replicas\") == 2:
        sys.exit(0)
sys.exit(1)
"'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
