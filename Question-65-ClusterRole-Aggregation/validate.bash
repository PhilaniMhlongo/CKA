#!/bin/bash
# Validation script for Question 65 - ClusterRole Aggregation
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

SA="system:serviceaccount:d8f3b6a1c2e4-monitoring:monitor-sa"

echo "============================================"
echo " Validating Question 65: ClusterRole Aggregation"
echo "============================================"

check "Both labelled ClusterRoles exist" \
  bash -c 'kubectl get clusterrole monitoring-pods monitoring-nodes'

check "monitoring-admin has an aggregationRule selecting the label" \
  bash -c 'kubectl get clusterrole monitoring-admin -o jsonpath="{.aggregationRule.clusterRoleSelectors[0].matchLabels.rbac\.cka\.local/aggregate-to-monitoring}" | grep -qx true'

check "Controller auto-populated monitoring-admin with pods AND nodes rules" \
  bash -c '
    kubectl get clusterrole monitoring-admin -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
resources = set()
for rule in data.get(\"rules\", []) or []:
    resources.update(rule.get(\"resources\", []))
sys.exit(0 if {\"pods\", \"nodes\"} <= resources else 1)
"'

check "ClusterRoleBinding grants monitoring-admin to monitor-sa" \
  bash -c '
    kubectl get clusterrolebinding monitoring-admin-binding -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
if data[\"roleRef\"][\"name\"] != \"monitoring-admin\":
    sys.exit(1)
for s in data.get(\"subjects\", []):
    if s[\"kind\"] == \"ServiceAccount\" and s[\"name\"] == \"monitor-sa\" and s.get(\"namespace\") == \"d8f3b6a1c2e4-monitoring\":
        sys.exit(0)
sys.exit(1)
"'

check "SA can list nodes" \
  kubectl auth can-i list nodes --as="$SA"

check "SA can list pods cluster-wide" \
  kubectl auth can-i list pods --as="$SA" -A

check "SA can NOT list secrets" \
  bash -c 'kubectl get --raw=/version >/dev/null 2>&1 && ! kubectl auth can-i list secrets --as="'"$SA"'" >/dev/null 2>&1'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
