#!/bin/bash
# Validation script for Question 51 - NetworkPolicy with Port
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
echo " Validating Question 51: NetworkPolicy with Port"
echo "============================================"

check "NetworkPolicy 'db-policy' exists" \
  kubectl get networkpolicy db-policy -n 7b43d4b5300b-networking

check "Policy selects pods with role=db" \
  bash -c 'kubectl get networkpolicy db-policy -n 7b43d4b5300b-networking -o jsonpath="{.spec.podSelector.matchLabels.role}" | grep -qx db'

check "Ingress allowed only from role=frontend on TCP 3306" \
  bash -c '
    kubectl get networkpolicy db-policy -n 7b43d4b5300b-networking -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for rule in data[\"spec\"].get(\"ingress\", []):
    from_ok = any(f.get(\"podSelector\", {}).get(\"matchLabels\", {}).get(\"role\") == \"frontend\"
                  for f in rule.get(\"from\", []))
    port_ok = any(p.get(\"port\") == 3306 and p.get(\"protocol\", \"TCP\") == \"TCP\"
                  for p in rule.get(\"ports\", []))
    if from_ok and port_ok:
        sys.exit(0)
sys.exit(1)
"'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
