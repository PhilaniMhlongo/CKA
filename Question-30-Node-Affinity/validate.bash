#!/bin/bash
# Validation script for Question 30 - Node Affinity
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
echo " Validating Question 30: Node Affinity"
echo "============================================"

check "At least one node is labelled disk=ssd" \
  bash -c 'kubectl get nodes -l disk=ssd --no-headers 2>/dev/null | grep -q .'

check "Deployment 'app-scheduling' exists with 3 replicas" \
  bash -c 'kubectl get deployment app-scheduling -n eda9e0ec987a-scheduling -o jsonpath="{.spec.replicas}" | grep -qx 3'

check "Deployment uses required node affinity for disk=ssd" \
  bash -c '
    kubectl get deployment app-scheduling -n eda9e0ec987a-scheduling -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
aff = data[\"spec\"][\"template\"][\"spec\"].get(\"affinity\", {}).get(\"nodeAffinity\", {})
req = aff.get(\"requiredDuringSchedulingIgnoredDuringExecution\", {})
for term in req.get(\"nodeSelectorTerms\", []):
    for expr in term.get(\"matchExpressions\", []):
        if expr[\"key\"] == \"disk\" and expr[\"operator\"] == \"In\" and \"ssd\" in expr.get(\"values\", []):
            sys.exit(0)
sys.exit(1)
"'

check "All scheduled pods run on a disk=ssd node" \
  bash -c '
    LABELLED=$(kubectl get nodes -l disk=ssd -o jsonpath="{.items[*].metadata.name}")
    kubectl get pods -n eda9e0ec987a-scheduling -l app=app-scheduling -o jsonpath="{.items[*].spec.nodeName}" | python3 -c "
import sys
labelled = set(\"$LABELLED\".split())
nodes = sys.stdin.read().split()
if nodes and all(n in labelled for n in nodes):
    sys.exit(0)
sys.exit(1)
"'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
