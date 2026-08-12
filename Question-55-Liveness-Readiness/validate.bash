#!/bin/bash
# Validation script for Question 55 - Liveness + Readiness Probes
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
echo " Validating Question 55: Liveness + Readiness Probes"
echo "============================================"

check "Pod 'health-check' exists and uses nginx" \
  bash -c 'kubectl get pod health-check -o jsonpath="{.spec.containers[0].image}" | grep -q nginx'

check "Liveness probe: HTTP GET / on port 80, initialDelaySeconds 5" \
  bash -c 'kubectl get pod health-check -o jsonpath="{.spec.containers[0].livenessProbe.httpGet.path}|{.spec.containers[0].livenessProbe.httpGet.port}|{.spec.containers[0].livenessProbe.initialDelaySeconds}" | grep -qx "/|80|5"'

check "Readiness probe: HTTP GET / on port 80, initialDelaySeconds 5" \
  bash -c 'kubectl get pod health-check -o jsonpath="{.spec.containers[0].readinessProbe.httpGet.path}|{.spec.containers[0].readinessProbe.httpGet.port}|{.spec.containers[0].readinessProbe.initialDelaySeconds}" | grep -qx "/|80|5"'

check "Pod is Running and Ready" \
  bash -c 'kubectl get pod health-check -o jsonpath="{.status.conditions[?(@.type==\"Ready\")].status}" | grep -qx True'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
