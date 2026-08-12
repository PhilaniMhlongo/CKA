#!/bin/bash
# Validation script for Question 35 - DNS Test to File
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
echo " Validating Question 35: DNS Test to File"
echo "============================================"

check "Deployment 'dns-app' exists with 2 replicas" \
  bash -c 'kubectl get deployment dns-app -n eda9e0ec987a-dns-config -o jsonpath="{.spec.replicas}" | grep -qx 2'

check "Service 'dns-svc' is ClusterIP and selects app=dns-app" \
  bash -c 'kubectl get svc dns-svc -n eda9e0ec987a-dns-config -o jsonpath="{.spec.type}|{.spec.selector.app}" | grep -qx "ClusterIP|dns-app"'

check "Pod 'dns-tester' uses the infoblox/dnstools image" \
  bash -c 'kubectl get pod dns-tester -n eda9e0ec987a-dns-config -o jsonpath="{.spec.containers[0].image}" | grep -q "infoblox/dnstools"'

check "/tmp/dns-test.txt in the pod contains nslookup results for dns-svc" \
  bash -c 'kubectl exec dns-tester -n eda9e0ec987a-dns-config -- cat /tmp/dns-test.txt 2>/dev/null | grep -q dns-svc'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
