#!/bin/bash
# Validation script for Question 39 - LimitRange + ResourceQuota
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
echo " Validating Question 39: LimitRange + ResourceQuota"
echo "============================================"

check "LimitRange 'resource-limits' has correct defaults, requests and max" \
  bash -c '
    kubectl get limitrange resource-limits -n eda9e0ec987a-limits -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for lim in data[\"spec\"][\"limits\"]:
    if lim.get(\"type\") != \"Container\":
        continue
    ok = (lim.get(\"default\", {}).get(\"cpu\") == \"200m\"
          and lim.get(\"default\", {}).get(\"memory\") == \"256Mi\"
          and lim.get(\"defaultRequest\", {}).get(\"cpu\") == \"100m\"
          and lim.get(\"defaultRequest\", {}).get(\"memory\") == \"128Mi\"
          and lim.get(\"max\", {}).get(\"cpu\") == \"500m\"
          and lim.get(\"max\", {}).get(\"memory\") == \"512Mi\")
    if ok:
        sys.exit(0)
sys.exit(1)
"'

check "ResourceQuota 'compute-quota' has cpu=2, memory=2Gi, pods=5" \
  bash -c 'kubectl get resourcequota compute-quota -n eda9e0ec987a-limits -o jsonpath="{.spec.hard.cpu}|{.spec.hard.memory}|{.spec.hard.pods}" | grep -qx "2|2Gi|5"'

check "Deployment 'test-limits' exists with 2 replicas" \
  bash -c 'kubectl get deployment test-limits -n eda9e0ec987a-limits -o jsonpath="{.spec.replicas}" | grep -qx 2'

check "Pods inherited the LimitRange default limits (cpu 200m / memory 256Mi)" \
  bash -c '
    kubectl get pods -n eda9e0ec987a-limits -l app=test-limits -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
if not data[\"items\"]:
    sys.exit(1)
for pod in data[\"items\"]:
    lims = pod[\"spec\"][\"containers\"][0].get(\"resources\", {}).get(\"limits\", {})
    if lims.get(\"cpu\") == \"200m\" and lims.get(\"memory\") == \"256Mi\":
        sys.exit(0)
sys.exit(1)
"'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
