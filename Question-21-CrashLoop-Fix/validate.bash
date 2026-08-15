#!/bin/bash
# Validation script for Question 21 - CrashLoop Fix
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

echo "======================================"
echo " Validating Question 21: CrashLoop Fix"
echo "======================================"

# 1. Deployment still exists
check "Deployment 'webapp' exists in 'shopping'" \
  kubectl get deployment webapp -n shopping

# 2. All replicas are ready
check "All webapp replicas are Ready" \
  bash -c '
    DESIRED=$(kubectl get deployment webapp -n shopping -o jsonpath="{.spec.replicas}" 2>/dev/null)
    READY=$(kubectl get deployment webapp -n shopping -o jsonpath="{.status.readyReplicas}" 2>/dev/null)
    [[ -n "$DESIRED" && -n "$READY" && "$DESIRED" == "$READY" ]]
  '

# 3. No pods are currently in CrashLoopBackOff
check "No webapp pods are in CrashLoopBackOff" \
  bash -c 'kubectl get --raw=/version >/dev/null 2>&1 && ! kubectl get pods -n shopping -l app=webapp --no-headers 2>/dev/null | grep -q CrashLoopBackOff'

# 4. All webapp pods are Running
check "All webapp pods are Running" \
  bash -c '
    TOTAL_PODS=$(kubectl get pods -n shopping -l app=webapp --no-headers 2>/dev/null | wc -l)
    RUNNING_PODS=$(kubectl get pods -n shopping -l app=webapp --no-headers 2>/dev/null | grep -c Running)
    [[ "$TOTAL_PODS" -gt 0 && "$TOTAL_PODS" == "$RUNNING_PODS" ]]
  '

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."
exit $FAIL
