#!/bin/bash
# Validation script for Question 19 - WordPress Pod Scheduling

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
echo " Validating Question 19: WordPress Scheduling"
echo "==========================================="

# 1. Namespace exists
check "Namespace 'relative-fawn' exists" \
  kubectl get namespace relative-fawn

# 2. WordPress deployment exists
check "Deployment 'wordpress' exists in relative-fawn" \
  kubectl get deployment wordpress -n relative-fawn

# 3. WordPress has 3 replicas configured
check "WordPress deployment has 3 replicas" \
  bash -c '[[ "$(kubectl get deployment wordpress -n relative-fawn -o jsonpath="{.spec.replicas}")" == "3" ]]'

# 4. All 3 WordPress pods are Running
check "All 3 WordPress pods are Running" \
  bash -c '[[ $(kubectl get pods -n relative-fawn -l app=wordpress --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l) -eq 3 ]]'

# 5. No Pending pods in the namespace
check "No Pending pods in relative-fawn" \
  bash -c '[[ $(kubectl get pods -n relative-fawn --field-selector=status.phase=Pending --no-headers 2>/dev/null | wc -l) -eq 0 ]]'

# 6. WordPress pods have CPU requests set
check "WordPress container has CPU requests defined" \
  bash -c '
    REQ=$(kubectl get deployment wordpress -n relative-fawn -o jsonpath="{.spec.template.spec.containers[0].resources.requests.cpu}" 2>/dev/null)
    [[ -n "$REQ" && "$REQ" != "0" ]]
  '

# 7. WordPress CPU requests were increased from 100m (properly sized)
check "CPU requests evenly divide the node's allocatable CPU across 3 replicas" \
  python3 "$EVEN_SPLIT" --namespace relative-fawn --selector app=wordpress \
    --replicas 3 --resource cpu

# 8. Memory requests likewise divide the node, scored against real allocatable
check "Memory requests evenly divide the node's allocatable memory across 3 replicas" \
  python3 "$EVEN_SPLIT" --namespace relative-fawn --selector app=wordpress \
    --replicas 3 --resource memory

# 9. Limits were NOT modified. Compared as parsed quantities so an equivalent
#    but differently-written value ("0.3" for "300m") is not marked wrong.
limit_unchanged() {
  local field="$1" expected="$2" actual
  actual=$(kubectl get deployment wordpress -n relative-fawn \
    -o jsonpath="{.spec.template.spec.containers[0].resources.limits.$field}" 2>/dev/null)
  python3 "$QUANTITY" equals "$actual" "$expected"
}

check "WordPress memory limit unchanged (still 500Mi)" \
  limit_unchanged memory 500Mi

# 10. CPU limit likewise untouched
check "WordPress CPU limit unchanged (still 300m)" \
  limit_unchanged cpu 300m

echo ""
echo "==========================================="
echo " Summary"
echo "==========================================="
echo "  Passed: $PASS/$TOTAL"
echo "  Failed: $FAIL/$TOTAL"
echo "==========================================="

if [ $FAIL -eq 0 ]; then
  echo "  Result: SUCCESS"
  exit 0
else
  echo "  Result: FAILURE"
  exit 1
fi

