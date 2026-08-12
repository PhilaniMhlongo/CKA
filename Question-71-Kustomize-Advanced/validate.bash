#!/bin/bash
# Validation script for Question 71 - Advanced Kustomize
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
echo " Validating Question 71: Advanced Kustomize"
echo "============================================"

check "Base and overlay kustomization files exist" \
  bash -c 'test -f /tmp/exam/kustomize-adv/base/kustomization.yaml && test -f /tmp/exam/kustomize-adv/overlays/production/kustomization.yaml'

check "Deployment 'prod-api' exists with 3 replicas" \
  bash -c 'kubectl get deployment prod-api -n d8f3b6a1c2e4-prod -o jsonpath="{.spec.replicas}" | grep -qx 3'

check "Deployment gained the readinessProbe via the patch" \
  bash -c 'kubectl get deployment prod-api -n d8f3b6a1c2e4-prod -o jsonpath="{.spec.template.spec.containers[0].readinessProbe.httpGet.path}|{.spec.template.spec.containers[0].readinessProbe.httpGet.port}" | grep -qx "/|80"'

check "Deployment carries annotation owner=platform-team" \
  bash -c 'kubectl get deployment prod-api -n d8f3b6a1c2e4-prod -o jsonpath="{.metadata.annotations.owner}" | grep -qx "platform-team"'

check "Service 'prod-api-svc' exists" \
  kubectl get svc prod-api-svc -n d8f3b6a1c2e4-prod

check "Generated secret 'prod-app-secret-*' exists with API_KEY" \
  bash -c '
    kubectl get secrets -n d8f3b6a1c2e4-prod -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for s in data[\"items\"]:
    if s[\"metadata\"][\"name\"].startswith(\"prod-app-secret\") and \"API_KEY\" in s.get(\"data\", {}):
        sys.exit(0)
sys.exit(1)
"'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
