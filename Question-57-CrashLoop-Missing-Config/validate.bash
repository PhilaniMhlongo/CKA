#!/bin/bash
# Validation script for Question 57 - Pod Stuck on Missing Configuration
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
echo " Validating Question 57: Pod Stuck on Missing Configuration"
echo "============================================"

check "ConfigMap 'app-settings' exists with key db_host" \
  bash -c 'kubectl get configmap app-settings -n d8f3b6a1c2e4-crashloop -o jsonpath="{.data.db_host}" | grep -q .'

check "Secret 'app-credentials' exists with keys DB_USER and DB_PASS" \
  bash -c '
    kubectl get secret app-credentials -n d8f3b6a1c2e4-crashloop -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
keys = set(data.get(\"data\", {}).keys())
sys.exit(0 if {\"DB_USER\", \"DB_PASS\"} <= keys else 1)
"'

check "Deployment spec was not modified (still references both resources)" \
  bash -c '
    kubectl get deployment config-app -n d8f3b6a1c2e4-crashloop -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
spec = data[\"spec\"][\"template\"][\"spec\"]
init = spec.get(\"initContainers\", [{}])[0]
cm_ok = any(e.get(\"valueFrom\", {}).get(\"configMapKeyRef\", {}).get(\"name\") == \"app-settings\"
            for e in init.get(\"env\", []))
sec_ok = any(ef.get(\"secretRef\", {}).get(\"name\") == \"app-credentials\"
             for ef in spec[\"containers\"][0].get(\"envFrom\", []))
sys.exit(0 if cm_ok and sec_ok else 1)
"'

check "Deployment has 1 ready replica" \
  bash -c 'READY=$(kubectl get deployment config-app -n d8f3b6a1c2e4-crashloop -o jsonpath="{.status.readyReplicas}"); [[ -n "$READY" && "$READY" -ge 1 ]]'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
