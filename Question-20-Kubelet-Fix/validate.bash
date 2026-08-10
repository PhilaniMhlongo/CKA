#!/bin/bash
# Validation script for Question 20 - Kubelet Fix
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
echo " Validating Question 20: Kubelet Fix"
echo "======================================"

# 1. kubelet service is active
check "kubelet service is active (running)" \
  bash -c 'systemctl is-active kubelet 2>/dev/null | grep -q "^active$"'

# 2. kubelet kubeconfig exists at the expected path
check "/etc/kubernetes/kubelet.conf exists" \
  bash -c '[[ -f /etc/kubernetes/kubelet.conf ]]'

# 3. No leftover disabled kubeconfig file
check "No leftover /etc/kubernetes/kubelet.conf.disabled file" \
  bash -c '[[ ! -f /etc/kubernetes/kubelet.conf.disabled ]]'

# 4. All nodes report Ready
check "All nodes are Ready" \
  bash -c '
    NOT_READY=$(kubectl get nodes --no-headers 2>/dev/null | grep -v " Ready" | wc -l)
    [[ "$NOT_READY" -eq 0 ]]
  '

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."
exit $FAIL
