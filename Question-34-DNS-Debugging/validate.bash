#!/bin/bash
# Validation script for Question 34 - DNS Debugging (dnsConfig)
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
echo " Validating Question 34: DNS Debugging (dnsConfig)"
echo "============================================"

check "Deployment 'web-app' exists with 3 replicas" \
  bash -c 'kubectl get deployment web-app -n eda9e0ec987a-dns-debug -o jsonpath="{.spec.replicas}" | grep -qx 3'

check "Service 'web-svc' is ClusterIP and selects app=web-app" \
  bash -c 'kubectl get svc web-svc -n eda9e0ec987a-dns-debug -o jsonpath="{.spec.type}|{.spec.selector.app}" | grep -qx "ClusterIP|web-app"'

check "Pod 'dns-test' has the custom dnsConfig search domain" \
  bash -c 'kubectl get pod dns-test -n eda9e0ec987a-dns-debug -o jsonpath="{.spec.dnsConfig.searches[*]}" | grep -q "eda9e0ec987a-dns-debug.svc.cluster.local"'

check "dns-test resolves 'web-svc'" \
  kubectl exec dns-test -n eda9e0ec987a-dns-debug -- nslookup web-svc

check "dns-test resolves the service FQDN" \
  kubectl exec dns-test -n eda9e0ec987a-dns-debug -- nslookup web-svc.eda9e0ec987a-dns-debug.svc.cluster.local

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
