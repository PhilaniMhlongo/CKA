#!/bin/bash
# Validation script for Question 43 - Rolling Update + Rollback
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
echo " Validating Question 43: Rolling Update + Rollback"
echo "============================================"

check "Deployment 'app-v1' exists with 4 replicas" \
  bash -c 'kubectl get deployment app-v1 -n eda9e0ec987a-upgrade -o jsonpath="{.spec.replicas}" | grep -qx 4'

check "RollingUpdate strategy with maxUnavailable=1 and maxSurge=1" \
  bash -c 'kubectl get deployment app-v1 -n eda9e0ec987a-upgrade -o jsonpath="{.spec.strategy.type}|{.spec.strategy.rollingUpdate.maxUnavailable}|{.spec.strategy.rollingUpdate.maxSurge}" | grep -qx "RollingUpdate|1|1"'

check "Image is back to nginx:1.19 (after rollback)" \
  bash -c 'kubectl get deployment app-v1 -n eda9e0ec987a-upgrade -o jsonpath="{.spec.template.spec.containers[0].image}" | grep -qx "nginx:1.19"'

check "Rollout history has at least 2 revisions" \
  bash -c 'REVS=$(kubectl rollout history deployment/app-v1 -n eda9e0ec987a-upgrade 2>/dev/null | grep -c "^[0-9]"); [[ "$REVS" -ge 2 ]]'

check "/tmp/exam/rollout-history.txt exists and is not empty" \
  test -s /tmp/exam/rollout-history.txt

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
