#!/bin/bash
# Validation script for Question 18 - kubectl patch
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
echo " Validating Question 18: kubectl patch"
echo "======================================"

NS="patch-ns"
QUESTION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QUANTITY="$QUESTION_DIR/../scripts/k8s_quantity.py"

# 1. Namespace patch-ns exists
check "Namespace 'patch-ns' exists" \
  kubectl get namespace "$NS"

# 2. Deployment resource-app exists
check "Deployment 'resource-app' exists in namespace '$NS'" \
  kubectl get deployment resource-app -n "$NS"

# Compare parsed quantities rather than raw strings, so a learner who writes
# "0.5" for the CPU limit is not failed for a cosmetic difference.
resource_is() {
  local kind="$1" field="$2" expected="$3" actual
  actual=$(kubectl get deployment resource-app -n "$NS" \
    -o jsonpath="{.spec.template.spec.containers[0].resources.$kind.$field}" 2>/dev/null)
  python3 "$QUANTITY" equals "$actual" "$expected"
}

# 3. CPU limit updated to 500m
check "Container CPU limit is 500m" resource_is limits cpu 500m

# 4. Memory limit updated to 512Mi
check "Container Memory limit is 512Mi" resource_is limits memory 512Mi

# 5. CPU request unchanged (100m)
check "Container CPU request is still 100m (unchanged)" resource_is requests cpu 100m

# 6. Memory request unchanged (128Mi)
check "Container Memory request is still 128Mi (unchanged)" resource_is requests memory 128Mi

# 7. Replicas still 2
check "Deployment still has 2 replicas" \
  bash -c '
    REPLICAS=$(kubectl get deployment resource-app -n '"$NS"' \
      -o jsonpath="{.spec.replicas}" 2>/dev/null)
    [[ "$REPLICAS" == "2" ]]
  '

# 8. Pods are running
check "Deployment pods are Running" \
  bash -c '
    kubectl get pods -n '"$NS"' --no-headers 2>/dev/null | grep -q Running
  '

# The previous version of this script grepped shell history to prove that
# `kubectl patch` (and not `kubectl edit`) had been used. That is not how the
# exam is graded - only the resulting cluster state is. The history checks were
# also unreliable, since an interactive shell may not have flushed its history
# yet when validation runs. Grade the end state only.

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."
exit $FAIL
