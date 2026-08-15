#!/bin/bash
# Validation script for Question 50 - RBAC in default Namespace
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
echo " Validating Question 50: RBAC in default Namespace"
echo "============================================"

check "ServiceAccount 'app-sa' exists in default" \
  kubectl get serviceaccount app-sa -n default

check "Role 'pod-reader' allows get and list on pods" \
  bash -c '
    kubectl get role pod-reader -n default -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for rule in data.get(\"rules\", []):
    if \"pods\" in rule.get(\"resources\", []) and \"\" in rule.get(\"apiGroups\", []):
        verbs = set(rule.get(\"verbs\", []))
        if {\"get\", \"list\"} <= verbs or \"*\" in verbs:
            sys.exit(0)
sys.exit(1)
"'

check "RoleBinding 'read-pods' binds pod-reader to app-sa" \
  bash -c '
    kubectl get rolebinding read-pods -n default -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
ref = data[\"roleRef\"]
if ref[\"kind\"] == \"Role\" and ref[\"name\"] == \"pod-reader\":
    for s in data.get(\"subjects\", []):
        if s[\"kind\"] == \"ServiceAccount\" and s[\"name\"] == \"app-sa\":
            sys.exit(0)
sys.exit(1)
"'

check "ServiceAccount can list pods" \
  kubectl auth can-i list pods --as=system:serviceaccount:default:app-sa -n default

check "ServiceAccount can NOT delete pods (least privilege)" \
  bash -c 'kubectl get --raw=/version >/dev/null 2>&1 && ! kubectl auth can-i delete pods --as=system:serviceaccount:default:app-sa -n default >/dev/null 2>&1'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
