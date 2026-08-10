#!/bin/bash
# Validation script for Question 22 - Scheduler Fix
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
echo " Validating Question 22: Scheduler Fix"
echo "======================================"

# 1. kube-scheduler pod is Running
check "kube-scheduler pod is Running" \
  bash -c 'kubectl get pods -n kube-system --no-headers 2>/dev/null | grep kube-scheduler | grep -q Running'

# 2. kube-scheduler --kubeconfig points at the real scheduler.conf
check "kube-scheduler --kubeconfig points at /etc/kubernetes/scheduler.conf" \
  bash -c 'grep -q -- "--kubeconfig=/etc/kubernetes/scheduler.conf" /etc/kubernetes/manifests/kube-scheduler.yaml'

# 3. No reference to the broken path remains
check "No reference to scheduler-wrong.conf remains" \
  bash -c '! grep -q "scheduler-wrong.conf" /etc/kubernetes/manifests/kube-scheduler.yaml'

# 4. stuck-pod has been scheduled to a node
check "stuck-pod is scheduled (has a node assigned)" \
  bash -c '[[ -n "$(kubectl get pod stuck-pod -n triage -o jsonpath="{.spec.nodeName}" 2>/dev/null)" ]]'

# 5. stuck-pod is Running
check "stuck-pod is Running" \
  bash -c 'kubectl get pod stuck-pod -n triage --no-headers 2>/dev/null | grep -q Running'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."
exit $FAIL
