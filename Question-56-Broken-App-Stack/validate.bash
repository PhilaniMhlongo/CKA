#!/bin/bash
# Validation script for Question 56 - Broken App Stack
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
echo " Validating Question 56: Broken App Stack"
echo "============================================"

check "Deployment no longer uses the bogus nginx:1.99-fake image" \
  bash -c 'kubectl get --raw=/version >/dev/null 2>&1 && ! kubectl get deployment web-stack -n d8f3b6a1c2e4-broken-stack -o jsonpath="{.spec.template.spec.containers[0].image}" | grep -q "1.99-fake"'

check "Deployment has 2 ready replicas" \
  bash -c 'READY=$(kubectl get deployment web-stack -n d8f3b6a1c2e4-broken-stack -o jsonpath="{.status.readyReplicas}"); [[ -n "$READY" && "$READY" -ge 2 ]]'

check "Service selector matches the pod label app=web-stack" \
  bash -c 'kubectl get svc web-stack-svc -n d8f3b6a1c2e4-broken-stack -o jsonpath="{.spec.selector.app}" | grep -qx "web-stack"'

check "Service targetPort is 80" \
  bash -c 'kubectl get svc web-stack-svc -n d8f3b6a1c2e4-broken-stack -o jsonpath="{.spec.ports[0].targetPort}" | grep -qx 80'

check "Service has healthy endpoints" \
  bash -c 'kubectl get endpoints web-stack-svc -n d8f3b6a1c2e4-broken-stack -o jsonpath="{.subsets[0].addresses[0].ip}" | grep -q .'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
