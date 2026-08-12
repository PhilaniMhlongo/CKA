#!/bin/bash
# Validation script for Question 70 - Node Maintenance Blocked by a PDB
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
echo " Validating Question 70: Node Maintenance Blocked by a PDB"
echo "============================================"

check "PDB 'pdb-app-guard' still exists with maxUnavailable 1" \
  bash -c 'kubectl get pdb pdb-app-guard -n d8f3b6a1c2e4-pdb-drain -o jsonpath="{.spec.maxUnavailable}" | grep -qx 1'

check "At least one node is cordoned (SchedulingDisabled)" \
  bash -c '
    kubectl get nodes -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
sys.exit(0 if any(n[\"spec\"].get(\"unschedulable\") for n in data[\"items\"]) else 1)
"'

check "No pdb-app pod runs on a cordoned node" \
  bash -c '
    kubectl get pods -n d8f3b6a1c2e4-pdb-drain -l app=pdb-app -o json 2>/dev/null > /tmp/q70-pods.json
    kubectl get nodes -o json 2>/dev/null | python3 -c "
import json, sys
nodes = json.load(sys.stdin)
cordoned = {n[\"metadata\"][\"name\"] for n in nodes[\"items\"] if n[\"spec\"].get(\"unschedulable\")}
pods = json.load(open(\"/tmp/q70-pods.json\"))
if not cordoned or not pods[\"items\"]:
    sys.exit(1)
for pod in pods[\"items\"]:
    if pod[\"spec\"].get(\"nodeName\") in cordoned:
        sys.exit(1)
sys.exit(0)
"'

check "Deployment pdb-app still has available replicas" \
  bash -c 'AVAIL=$(kubectl get deployment pdb-app -n d8f3b6a1c2e4-pdb-drain -o jsonpath="{.status.availableReplicas}"); [[ -n "$AVAIL" && "$AVAIL" -ge 1 ]]'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
