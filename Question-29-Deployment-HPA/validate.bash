#!/bin/bash
# Validation script for Question 29 - Deployment + HPA
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
echo " Validating Question 29: Deployment + HPA"
echo "============================================"

check "Deployment 'scaling-app' exists" \
  kubectl get deployment scaling-app -n eda9e0ec987a-scaling

check "Deployment has at least 2 replicas" \
  bash -c 'REPLICAS=$(kubectl get deployment scaling-app -n eda9e0ec987a-scaling -o jsonpath="{.spec.replicas}"); [[ "$REPLICAS" -ge 2 ]]'

check "Container has correct requests (200m/256Mi) and limits (500m/512Mi)" \
  bash -c 'kubectl get deployment scaling-app -n eda9e0ec987a-scaling -o jsonpath="{.spec.template.spec.containers[0].resources.requests.cpu}|{.spec.template.spec.containers[0].resources.requests.memory}|{.spec.template.spec.containers[0].resources.limits.cpu}|{.spec.template.spec.containers[0].resources.limits.memory}" | grep -qx "200m|256Mi|500m|512Mi"'

check "HPA targets 'scaling-app' with min 2 / max 5 at 70% CPU" \
  bash -c '
    kubectl get hpa -n eda9e0ec987a-scaling -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for hpa in data[\"items\"]:
    spec = hpa[\"spec\"]
    if spec.get(\"scaleTargetRef\", {}).get(\"name\") != \"scaling-app\":
        continue
    if spec.get(\"minReplicas\") != 2 or spec.get(\"maxReplicas\") != 5:
        continue
    if spec.get(\"targetCPUUtilizationPercentage\") == 70:
        sys.exit(0)
    for m in spec.get(\"metrics\", []):
        res = m.get(\"resource\", {})
        if res.get(\"name\") == \"cpu\" and res.get(\"target\", {}).get(\"averageUtilization\") == 70:
            sys.exit(0)
sys.exit(1)
"'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
