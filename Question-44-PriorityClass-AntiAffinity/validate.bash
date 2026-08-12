#!/bin/bash
# Validation script for Question 44 - PriorityClasses + Pod Anti-Affinity
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
echo " Validating Question 44: PriorityClasses + Pod Anti-Affinity"
echo "============================================"

check "PriorityClass 'eda9e0ec987a-high-priority' has value 1000 and PreemptLowerPriority" \
  bash -c 'kubectl get priorityclass eda9e0ec987a-high-priority -o jsonpath="{.value}|{.preemptionPolicy}" | grep -qx "1000|PreemptLowerPriority"'

check "PriorityClass 'eda9e0ec987a-low-priority' has value 100 and PreemptLowerPriority" \
  bash -c 'kubectl get priorityclass eda9e0ec987a-low-priority -o jsonpath="{.value}|{.preemptionPolicy}" | grep -qx "100|PreemptLowerPriority"'

check "Pod 'high-priority' uses the high PriorityClass" \
  bash -c 'kubectl get pod high-priority -n eda9e0ec987a-scheduling -o jsonpath="{.spec.priorityClassName}" | grep -qx eda9e0ec987a-high-priority'

check "Pod 'low-priority' uses the low PriorityClass" \
  bash -c 'kubectl get pod low-priority -n eda9e0ec987a-scheduling -o jsonpath="{.spec.priorityClassName}" | grep -qx eda9e0ec987a-low-priority'

check "Both pods declare required podAntiAffinity on kubernetes.io/hostname" \
  bash -c '
    kubectl get pods high-priority low-priority -n eda9e0ec987a-scheduling -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for pod in data[\"items\"]:
    terms = pod[\"spec\"].get(\"affinity\", {}).get(\"podAntiAffinity\", {}).get(\"requiredDuringSchedulingIgnoredDuringExecution\", [])
    if not any(t.get(\"topologyKey\") == \"kubernetes.io/hostname\" for t in terms):
        sys.exit(1)
sys.exit(0)
"'

check "Pods do not share a node" \
  bash -c '
    kubectl get pods high-priority low-priority -n eda9e0ec987a-scheduling -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
nodes = [p[\"spec\"].get(\"nodeName\") for p in data[\"items\"]]
# If only one pod could schedule, anti-affinity is doing its job - that also passes
scheduled = [n for n in nodes if n]
sys.exit(1 if len(scheduled) == 2 and scheduled[0] == scheduled[1] else 0)
"'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
