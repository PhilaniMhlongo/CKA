#!/bin/bash
# Validation script for Question 25 - CoreDNS
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

echo "==========================================="
echo " Validating Question 25: CoreDNS"
echo "==========================================="

COREFILE=$(kubectl get configmap coredns -n kube-system -o jsonpath='{.data.Corefile}' 2>/dev/null)

# Lookups below run from a throwaway pod so the query travels the same cluster
# DNS path the task is about, rather than the host's resolver.

# 1. CoreDNS is healthy at all
check "CoreDNS deployment has at least one available replica" \
  bash -c '
    AVAIL=$(kubectl get deployment coredns -n kube-system -o jsonpath="{.status.availableReplicas}" 2>/dev/null)
    [[ ${AVAIL:-0} -ge 1 ]]
  '

check "kube-dns Service has endpoints" \
  bash -c '
    EP=$(kubectl get endpoints kube-dns -n kube-system -o jsonpath="{.subsets[0].addresses[0].ip}" 2>/dev/null)
    [[ -n "$EP" ]]
  '

# 2. Task 1 - upstream forwarding restored to the node resolver
check "Corefile forwards upstream queries to /etc/resolv.conf" \
  bash -c '[[ "$1" == *"forward . /etc/resolv.conf"* ]]' _ "$COREFILE"

check "Corefile no longer points at the blackhole address 240.0.0.1" \
  bash -c '[[ "$1" != *"240.0.0.1"* ]]' _ "$COREFILE"

# 3. Nothing else was torn out while fixing it
check "Corefile still serves the cluster.local zone via the kubernetes plugin" \
  bash -c '[[ "$1" == *"kubernetes cluster.local"* ]]' _ "$COREFILE"

# 4. Task 2 - the rewrite rule is present and points the right way
check "Corefile contains a rewrite for backend.dns-lab.example.com" \
  bash -c '
    echo "$1" | grep -Eq "rewrite[[:space:]]+name([[:space:]]+[a-z]+)?[[:space:]]+backend\.dns-lab\.example\.com[[:space:]]+backend\.dns-lab\.svc\.cluster\.local"
  ' _ "$COREFILE"

# 5. Task 3 - the running pods are serving the current ConfigMap, not a stale one.
#    These lookups are the real test; the Corefile checks above only prove intent.
check "In-cluster name backend.dns-lab.svc.cluster.local resolves" \
  bash -c '
    OUT=$(kubectl -n dns-lab run dnscheck-svc --image=busybox:stable --restart=Never \
      --rm --attach --quiet --timeout=60s -- nslookup backend.dns-lab.svc.cluster.local 2>/dev/null)
    echo "$OUT" | grep -q "Address"
  '

check "Rewritten name backend.dns-lab.example.com resolves" \
  bash -c '
    OUT=$(kubectl -n dns-lab run dnscheck-rewrite --image=busybox:stable --restart=Never \
      --rm --attach --quiet --timeout=60s -- nslookup backend.dns-lab.example.com 2>/dev/null)
    echo "$OUT" | grep -q "Address"
  '

check "Rewritten name resolves to the backend Service ClusterIP" \
  bash -c '
    CLUSTER_IP=$(kubectl get svc backend -n dns-lab -o jsonpath="{.spec.clusterIP}" 2>/dev/null)
    OUT=$(kubectl -n dns-lab run dnscheck-match --image=busybox:stable --restart=Never \
      --rm --attach --quiet --timeout=60s -- nslookup backend.dns-lab.example.com 2>/dev/null)
    [[ -n "$CLUSTER_IP" ]] && echo "$OUT" | grep -q "$CLUSTER_IP"
  '

echo ""
# External resolution is reported but not graded: a cluster with no route to the
# internet would fail it for reasons that have nothing to do with the answer.
echo "  INFO: external resolution (not graded - needs internet from the cluster)"
if kubectl -n dns-lab run dnscheck-ext --image=busybox:stable --restart=Never \
     --rm --attach --quiet --timeout=60s -- nslookup kubernetes.io 2>/dev/null | grep -q "Address"; then
  echo "        external lookup of kubernetes.io succeeded"
else
  echo "        external lookup of kubernetes.io failed or timed out"
fi

echo ""
echo "==========================================="
echo " Summary"
echo "==========================================="
echo "  Passed: $PASS/$TOTAL"
echo "  Failed: $FAIL/$TOTAL"
echo "==========================================="

[[ $FAIL -eq 0 ]] && echo "  Result: SUCCESS" || echo "  Result: FAILURE"
exit $FAIL
