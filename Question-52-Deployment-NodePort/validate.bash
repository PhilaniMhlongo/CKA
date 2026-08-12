#!/bin/bash
# Validation script for Question 52 - Deployment + NodePort Service
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
echo " Validating Question 52: Deployment + NodePort Service"
echo "============================================"

check "Deployment 'web-app' exists with 3 replicas" \
  bash -c 'kubectl get deployment web-app -o jsonpath="{.spec.replicas}" | grep -qx 3'

check "Deployment uses image nginx:1.19" \
  bash -c 'kubectl get deployment web-app -o jsonpath="{.spec.template.spec.containers[0].image}" | grep -qx "nginx:1.19"'

check "Service 'web-service' is type NodePort" \
  bash -c 'kubectl get svc web-service -o jsonpath="{.spec.type}" | grep -qx NodePort'

check "Service exposes port 80 and targets app=web-app" \
  bash -c 'kubectl get svc web-service -o jsonpath="{.spec.ports[0].port}|{.spec.selector.app}" | grep -qx "80|web-app"'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
