#!/bin/bash
# Validation script for Question 64 - Cluster DNS Outage
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
echo " Validating Question 64: Cluster DNS Outage"
echo "============================================"

check "CoreDNS has at least 1 ready replica" \
  bash -c 'READY=$(kubectl get deployment coredns -n kube-system -o jsonpath="{.status.readyReplicas}"); [[ -n "$READY" && "$READY" -ge 1 ]]'

check "Corefile zone is cluster.local again (no cluster.broken)" \
  bash -c '
    COREFILE=$(kubectl get configmap coredns -n kube-system -o jsonpath="{.data.Corefile}")
    echo "$COREFILE" | grep -q "cluster.local" && ! echo "$COREFILE" | grep -q "cluster.broken"
  '

check "dns-client resolves kubernetes.default.svc.cluster.local" \
  kubectl exec dns-client -n d8f3b6a1c2e4-dns-debug -- nslookup kubernetes.default.svc.cluster.local

check "dns-client resolves a short service name (kubernetes.default)" \
  kubectl exec dns-client -n d8f3b6a1c2e4-dns-debug -- nslookup kubernetes.default

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
