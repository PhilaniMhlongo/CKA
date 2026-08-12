#!/bin/bash
# Validation script for Question 45 - Troubleshoot a Broken Deployment
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
echo " Validating Question 45: Troubleshoot a Broken Deployment"
echo "============================================"

check "containerPort is 80" \
  bash -c 'kubectl get deployment failing-app -n eda9e0ec987a-troubleshoot -o jsonpath="{.spec.template.spec.containers[0].ports[0].containerPort}" | grep -qx 80'

check "Memory limit is 256Mi" \
  bash -c 'kubectl get deployment failing-app -n eda9e0ec987a-troubleshoot -o jsonpath="{.spec.template.spec.containers[0].resources.limits.memory}" | grep -qx 256Mi'

check "Liveness probe points to port 80" \
  bash -c 'kubectl get deployment failing-app -n eda9e0ec987a-troubleshoot -o jsonpath="{.spec.template.spec.containers[0].livenessProbe.httpGet.port}" | grep -qx 80'

check "Deployment has available replicas" \
  bash -c 'AVAIL=$(kubectl get deployment failing-app -n eda9e0ec987a-troubleshoot -o jsonpath="{.status.availableReplicas}"); [[ -n "$AVAIL" && "$AVAIL" -ge 1 ]]'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
