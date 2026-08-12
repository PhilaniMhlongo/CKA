#!/bin/bash
# Validation script for Question 67 - Static Pod
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
echo " Validating Question 67: Static Pod"
echo "============================================"

check "Manifest file exists in the static pod path" \
  test -f /etc/kubernetes/manifests/static-web.yaml

check "Mirror pod static-web-* exists, is Running and owned by the Node" \
  bash -c '
    kubectl get pods -n default -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for pod in data[\"items\"]:
    name = pod[\"metadata\"][\"name\"]
    if not name.startswith(\"static-web\"):
        continue
    owners = pod[\"metadata\"].get(\"ownerReferences\", [])
    if pod[\"status\"].get(\"phase\") == \"Running\" and any(o[\"kind\"] == \"Node\" for o in owners):
        sys.exit(0)
sys.exit(1)
"'

check "Static pod uses image nginx:1.25" \
  bash -c 'kubectl get pods -n default -l role=static-demo -o jsonpath="{.items[0].spec.containers[0].image}" | grep -qx "nginx:1.25"'

check "Static pod carries label role=static-demo" \
  bash -c 'kubectl get pods -n default -l role=static-demo --no-headers 2>/dev/null | grep -q static-web'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
