#!/bin/bash
# Validation script for Question 53 - Pod with Resource Requests/Limits
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
echo " Validating Question 53: Pod with Resource Requests/Limits"
echo "============================================"

check "Pod 'resource-pod' exists and uses nginx" \
  bash -c 'kubectl get pod resource-pod -n 7b43d4b5300b-monitoring -o jsonpath="{.spec.containers[0].image}" | grep -q nginx'

check "Requests are cpu 100m / memory 128Mi" \
  bash -c 'kubectl get pod resource-pod -n 7b43d4b5300b-monitoring -o jsonpath="{.spec.containers[0].resources.requests.cpu}|{.spec.containers[0].resources.requests.memory}" | grep -qx "100m|128Mi"'

check "Limits are cpu 200m / memory 256Mi" \
  bash -c 'kubectl get pod resource-pod -n 7b43d4b5300b-monitoring -o jsonpath="{.spec.containers[0].resources.limits.cpu}|{.spec.containers[0].resources.limits.memory}" | grep -qx "200m|256Mi"'

check "Pod is Running" \
  bash -c 'kubectl get pod resource-pod -n 7b43d4b5300b-monitoring -o jsonpath="{.status.phase}" | grep -qx Running'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
