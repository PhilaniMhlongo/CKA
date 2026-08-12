#!/bin/bash
# Validation script for Question 59 - RBAC Debugging
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

NS=d8f3b6a1c2e4-rbac-debug
SA="system:serviceaccount:${NS}:reporting-sa"

echo "============================================"
echo " Validating Question 59: RBAC Debugging"
echo "============================================"

check "SA can get pods" \
  kubectl auth can-i get pods --as="$SA" -n "$NS"

check "SA can list pods" \
  kubectl auth can-i list pods --as="$SA" -n "$NS"

check "SA can watch pods" \
  kubectl auth can-i watch pods --as="$SA" -n "$NS"

check "SA can NOT delete pods" \
  bash -c '! kubectl auth can-i delete pods --as="'"$SA"'" -n "'"$NS"'" >/dev/null 2>&1'

check "SA can NOT list secrets" \
  bash -c '! kubectl auth can-i list secrets --as="'"$SA"'" -n "'"$NS"'" >/dev/null 2>&1'

check "RoleBinding subject points at the correct namespace" \
  bash -c 'kubectl get rolebinding inspect-pods -n "'"$NS"'" -o jsonpath="{.subjects[0].namespace}" | grep -qx "'"$NS"'"'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
