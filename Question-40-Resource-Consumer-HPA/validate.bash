#!/bin/bash
# Validation script for Question 40 - Resource Consumer + HPA
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
echo " Validating Question 40: Resource Consumer + HPA"
echo "============================================"

check "Deployment 'resource-consumer' uses the resource-consumer:1.5 image" \
  bash -c 'kubectl get deployment resource-consumer -n eda9e0ec987a-monitoring -o jsonpath="{.spec.template.spec.containers[0].image}" | grep -q "resource-consumer:1.5"'

check "Deployment has at least 3 replicas" \
  bash -c 'REPLICAS=$(kubectl get deployment resource-consumer -n eda9e0ec987a-monitoring -o jsonpath="{.spec.replicas}"); [[ "$REPLICAS" -ge 3 ]]'

check "Container has correct requests (100m/128Mi) and limits (200m/256Mi)" \
  bash -c 'kubectl get deployment resource-consumer -n eda9e0ec987a-monitoring -o jsonpath="{.spec.template.spec.containers[0].resources.requests.cpu}|{.spec.template.spec.containers[0].resources.requests.memory}|{.spec.template.spec.containers[0].resources.limits.cpu}|{.spec.template.spec.containers[0].resources.limits.memory}" | grep -qx "100m|128Mi|200m|256Mi"'

check "HPA targets 'resource-consumer' with min 3 / max 6 at 50% CPU" \
  bash -c '
    kubectl get hpa -n eda9e0ec987a-monitoring -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for hpa in data[\"items\"]:
    spec = hpa[\"spec\"]
    if spec.get(\"scaleTargetRef\", {}).get(\"name\") != \"resource-consumer\":
        continue
    if spec.get(\"minReplicas\") != 3 or spec.get(\"maxReplicas\") != 6:
        continue
    if spec.get(\"targetCPUUtilizationPercentage\") == 50:
        sys.exit(0)
    for m in spec.get(\"metrics\", []):
        res = m.get(\"resource\", {})
        if res.get(\"name\") == \"cpu\" and res.get(\"target\", {}).get(\"averageUtilization\") == 50:
            sys.exit(0)
sys.exit(1)
"'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
