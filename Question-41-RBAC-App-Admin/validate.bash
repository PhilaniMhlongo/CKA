#!/bin/bash
# Validation script for Question 41 - RBAC (Role / RoleBinding / SA)
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

NS=eda9e0ec987a-cluster-admin
SA="system:serviceaccount:${NS}:app-admin"

echo "============================================"
echo " Validating Question 41: RBAC (Role / RoleBinding / SA)"
echo "============================================"

check "ServiceAccount 'app-admin' exists" \
  kubectl get serviceaccount app-admin -n "$NS"

check "Role 'app-admin' grants the required verbs" \
  bash -c '
    kubectl get role app-admin -n eda9e0ec987a-cluster-admin -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
need = {
    (\"\", \"pods\"): {\"list\", \"get\", \"watch\"},
    (\"apps\", \"deployments\"): {\"list\", \"get\", \"watch\", \"update\"},
    (\"\", \"configmaps\"): {\"create\", \"delete\"},
}
granted = {}
for rule in data.get(\"rules\", []):
    for g in rule.get(\"apiGroups\", []):
        for r in rule.get(\"resources\", []):
            granted.setdefault((g, r), set()).update(rule.get(\"verbs\", []))
for key, verbs in need.items():
    have = granted.get(key, set())
    if not (verbs <= have or \"*\" in have):
        sys.exit(1)
sys.exit(0)
"'

check "RoleBinding 'app-admin' binds the Role to the ServiceAccount" \
  bash -c '
    kubectl get rolebinding app-admin -n eda9e0ec987a-cluster-admin -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
ref = data[\"roleRef\"]
subs = data.get(\"subjects\", [])
if ref[\"kind\"] == \"Role\" and ref[\"name\"] == \"app-admin\":
    for s in subs:
        if s[\"kind\"] == \"ServiceAccount\" and s[\"name\"] == \"app-admin\":
            sys.exit(0)
sys.exit(1)
"'

check "Pod 'admin-pod' uses the app-admin ServiceAccount" \
  bash -c 'kubectl get pod admin-pod -n "'"$NS"'" -o jsonpath="{.spec.serviceAccountName}" | grep -qx app-admin'

check "ServiceAccount can list pods" \
  kubectl auth can-i list pods --as="$SA" -n "$NS"

check "ServiceAccount can update deployments" \
  kubectl auth can-i update deployments --as="$SA" -n "$NS"

check "ServiceAccount can NOT delete pods (least privilege)" \
  bash -c '! kubectl auth can-i delete pods --as="'"$SA"'" -n "'"$NS"'" >/dev/null 2>&1'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
