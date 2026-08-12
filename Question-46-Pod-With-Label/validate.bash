#!/bin/bash
# Validation script for Question 46 - Simple Pod with Label
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
echo " Validating Question 46: Simple Pod with Label"
echo "============================================"

check "Pod 'nginx-pod' exists" \
  kubectl get pod nginx-pod -n 7b43d4b5300b-app-team1

check "Pod uses image nginx:1.19" \
  bash -c 'kubectl get pod nginx-pod -n 7b43d4b5300b-app-team1 -o jsonpath="{.spec.containers[0].image}" | grep -qx "nginx:1.19"'

check "Pod has label run=nginx-pod" \
  bash -c 'kubectl get pod nginx-pod -n 7b43d4b5300b-app-team1 -o jsonpath="{.metadata.labels.run}" | grep -qx nginx-pod'

check "Pod is Running" \
  bash -c 'kubectl get pod nginx-pod -n 7b43d4b5300b-app-team1 -o jsonpath="{.status.phase}" | grep -qx Running'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
