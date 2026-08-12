#!/bin/bash
# Validation script for Question 31 - Pod Security (restricted)
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
echo " Validating Question 31: Pod Security (restricted)"
echo "============================================"

check "Namespace enforces the restricted Pod Security Standard" \
  bash -c 'kubectl get namespace eda9e0ec987a-security -o jsonpath="{.metadata.labels.pod-security\.kubernetes\.io/enforce}" | grep -qx restricted'

check "Pod 'secure-pod' exists" \
  kubectl get pod secure-pod -n eda9e0ec987a-security

check "Pod runs as non-root with runAsUser 1000" \
  bash -c 'kubectl get pod secure-pod -n eda9e0ec987a-security -o jsonpath="{.spec.securityContext.runAsNonRoot}|{.spec.securityContext.runAsUser}" | grep -qx "true|1000"'

check "Pod uses RuntimeDefault seccomp profile" \
  bash -c 'kubectl get pod secure-pod -n eda9e0ec987a-security -o jsonpath="{.spec.securityContext.seccompProfile.type}" | grep -qx RuntimeDefault'

check "Container disallows privilege escalation and drops ALL capabilities" \
  bash -c '
    kubectl get pod secure-pod -n eda9e0ec987a-security -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
sc = data[\"spec\"][\"containers\"][0].get(\"securityContext\", {})
if sc.get(\"allowPrivilegeEscalation\") is False and \"ALL\" in sc.get(\"capabilities\", {}).get(\"drop\", []):
    sys.exit(0)
sys.exit(1)
"'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
