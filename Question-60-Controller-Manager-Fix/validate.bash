#!/bin/bash
# Validation script for Question 60 - Broken Controller Manager
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
echo " Validating Question 60: Broken Controller Manager"
echo "============================================"

check "Manifest points at the correct controller-manager.conf again" \
  bash -c 'grep -q -- "--kubeconfig=/etc/kubernetes/controller-manager.conf" /etc/kubernetes/manifests/kube-controller-manager.yaml'

check "kube-controller-manager pod is Running and Ready" \
  bash -c '
    kubectl get pods -n kube-system -l component=kube-controller-manager -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for pod in data[\"items\"]:
    if pod[\"status\"].get(\"phase\") != \"Running\":
        continue
    for cond in pod[\"status\"].get(\"conditions\", []):
        if cond[\"type\"] == \"Ready\" and cond[\"status\"] == \"True\":
            sys.exit(0)
sys.exit(1)
"'

check "A ReplicaSet exists for kcm-test" \
  bash -c 'kubectl get rs -n d8f3b6a1c2e4-kcm-fix --no-headers 2>/dev/null | grep -q kcm-test'

check "Deployment kcm-test has 2 available replicas" \
  bash -c 'AVAIL=$(kubectl get deployment kcm-test -n d8f3b6a1c2e4-kcm-fix -o jsonpath="{.status.availableReplicas}"); [[ -n "$AVAIL" && "$AVAIL" -ge 2 ]]'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
