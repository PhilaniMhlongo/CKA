#!/bin/bash
# Validation script for Question 32 - Taints & Tolerations
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
echo " Validating Question 32: Taints & Tolerations"
echo "============================================"

check "A node carries taint special-workload=true:NoSchedule" \
  bash -c '
    kubectl get nodes -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for node in data[\"items\"]:
    for t in node[\"spec\"].get(\"taints\", []) or []:
        if t.get(\"key\") == \"special-workload\" and t.get(\"value\") == \"true\" and t.get(\"effect\") == \"NoSchedule\":
            sys.exit(0)
sys.exit(1)
"'

check "Deployment 'toleration-deploy' has the matching toleration" \
  bash -c '
    kubectl get deployment toleration-deploy -n eda9e0ec987a-scheduling -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for t in data[\"spec\"][\"template\"][\"spec\"].get(\"tolerations\", []) or []:
    if t.get(\"key\") == \"special-workload\" and t.get(\"value\") == \"true\" and t.get(\"effect\") == \"NoSchedule\":
        sys.exit(0)
sys.exit(1)
"'

check "Deployment 'normal-deploy' exists with 2 replicas" \
  bash -c 'kubectl get deployment normal-deploy -n eda9e0ec987a-scheduling -o jsonpath="{.spec.replicas}" | grep -qx 2'

check "normal-deploy pods are not on the tainted node" \
  bash -c '
    kubectl get pods -n eda9e0ec987a-scheduling -l app=normal-deploy -o json 2>/dev/null > /tmp/q32-pods.json
    kubectl get nodes -o json 2>/dev/null | python3 -c "
import json, sys
nodes = json.load(sys.stdin)
tainted = set()
for node in nodes[\"items\"]:
    for t in node[\"spec\"].get(\"taints\", []) or []:
        if t.get(\"key\") == \"special-workload\":
            tainted.add(node[\"metadata\"][\"name\"])
pods = json.load(open(\"/tmp/q32-pods.json\"))
if not pods[\"items\"]:
    sys.exit(1)
for pod in pods[\"items\"]:
    if pod[\"spec\"].get(\"nodeName\") in tainted:
        sys.exit(1)
sys.exit(0)
"'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
