#!/bin/bash
# Validation script for Question 37 - Kustomize Base + Overlay
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
echo " Validating Question 37: Kustomize Base + Overlay"
echo "============================================"

check "Base kustomization.yaml exists" \
  test -f /tmp/exam/kustomize/base/kustomization.yaml

check "Production overlay kustomization.yaml exists" \
  test -f /tmp/exam/kustomize/overlays/production/kustomization.yaml

check "Deployment 'nginx' exists in eda9e0ec987a-kustomize with 3 replicas" \
  bash -c 'kubectl get deployment nginx -n eda9e0ec987a-kustomize -o jsonpath="{.spec.replicas}" | grep -qx 3'

check "Deployment carries label environment=production" \
  bash -c 'kubectl get deployment nginx -n eda9e0ec987a-kustomize -o jsonpath="{.metadata.labels.environment}" | grep -qx production'

check "Generated ConfigMap 'web-content-*' exists" \
  bash -c 'kubectl get configmap -n eda9e0ec987a-kustomize -o name | grep -q web-content'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
