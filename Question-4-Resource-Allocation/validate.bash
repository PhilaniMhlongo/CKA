#!/bin/bash
# Validation script for Question 4 - Resource Allocation
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

QUESTION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVEN_SPLIT="$QUESTION_DIR/../scripts/check-even-split.py"
QUANTITY="$QUESTION_DIR/../scripts/k8s_quantity.py"

echo "==========================================="
echo " Validating Question 4: Resource Allocation"
echo "==========================================="

# 1. Deployment wordpress exists
check "Deployment 'wordpress' exists" \
  kubectl get deployment wordpress

# 2. Deployment is scaled to 3 replicas
check "Deployment has 3 replicas" \
  bash -c '[[ "$(kubectl get deployment wordpress -o jsonpath="{.spec.replicas}")" == "3" ]]'

# 3. All 3 pods are available
check "All 3 replicas are available" \
  bash -c '[[ $(kubectl get deployment wordpress -o jsonpath="{.status.availableReplicas}" 2>/dev/null) -ge 3 ]]'

# 4. Main containers have resource requests defined
check "Main containers have CPU requests set" \
  bash -c '
    REQ=$(kubectl get deployment wordpress -o jsonpath="{.spec.template.spec.containers[0].resources.requests.cpu}" 2>/dev/null)
    [[ -n "$REQ" ]]
  '

check "Main containers have memory requests set" \
  bash -c '
    REQ=$(kubectl get deployment wordpress -o jsonpath="{.spec.template.spec.containers[0].resources.requests.memory}" 2>/dev/null)
    [[ -n "$REQ" ]]
  '

# 5. Main containers have resource limits defined
check "Main containers have CPU limits set" \
  bash -c '
    LIM=$(kubectl get deployment wordpress -o jsonpath="{.spec.template.spec.containers[0].resources.limits.cpu}" 2>/dev/null)
    [[ -n "$LIM" ]]
  '

check "Main containers have memory limits set" \
  bash -c '
    LIM=$(kubectl get deployment wordpress -o jsonpath="{.spec.template.spec.containers[0].resources.limits.memory}" 2>/dev/null)
    [[ -n "$LIM" ]]
  '

# 6. Init containers must match the main containers exactly, on all four values.
#    The task says "exactly the same requests and limits", so check each one
#    rather than inferring from CPU requests alone.
init_matches_main() {
  local kind="$1" field="$2" init main
  init=$(kubectl get deployment wordpress \
    -o jsonpath="{.spec.template.spec.initContainers[0].resources.$kind.$field}" 2>/dev/null)
  main=$(kubectl get deployment wordpress \
    -o jsonpath="{.spec.template.spec.containers[0].resources.$kind.$field}" 2>/dev/null)
  # No init container in the deployment at all: nothing to compare.
  [[ -z "$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.initContainers[0].name}' 2>/dev/null)" ]] && return 0
  python3 "$QUANTITY" equals "$init" "$main"
}

check "Init container CPU request matches main container" init_matches_main requests cpu
check "Init container memory request matches main container" init_matches_main requests memory
check "Init container CPU limit matches main container" init_matches_main limits cpu
check "Init container memory limit matches main container" init_matches_main limits memory

# 6b. The requests actually divide the node's allocatable capacity across the 3
#     replicas, which is what the task is really asking for.
check "CPU requests evenly divide the node's allocatable CPU across 3 replicas" \
  python3 "$EVEN_SPLIT" --selector app=wordpress --replicas 3 --max-fraction 0.9 --resource cpu

check "Memory requests evenly divide the node's allocatable memory across 3 replicas" \
  python3 "$EVEN_SPLIT" --selector app=wordpress --replicas 3 --max-fraction 0.9 --resource memory

# 7. All pods are Running
check "All wordpress pods are Running" \
  bash -c '
    RUNNING=$(kubectl get pods -l app=wordpress --no-headers 2>/dev/null | grep -c Running)
    [[ $RUNNING -ge 3 ]]
  '

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."
exit $FAIL
