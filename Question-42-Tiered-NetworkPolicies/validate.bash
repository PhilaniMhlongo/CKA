#!/bin/bash
# Validation script for Question 42 - Tiered NetworkPolicies
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
echo " Validating Question 42: Tiered NetworkPolicies"
echo "============================================"

check "Deployments web, api and db exist" \
  bash -c 'kubectl get deployment web api db -n eda9e0ec987a-network'

check "web-policy: web egress only to api" \
  bash -c '
    kubectl get networkpolicy web-policy -n eda9e0ec987a-network -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
spec = data[\"spec\"]
if spec[\"podSelector\"].get(\"matchLabels\", {}).get(\"app\") != \"web\":
    sys.exit(1)
if \"Egress\" not in spec.get(\"policyTypes\", []):
    sys.exit(1)
for rule in spec.get(\"egress\", []):
    for to in rule.get(\"to\", []):
        if to.get(\"podSelector\", {}).get(\"matchLabels\", {}).get(\"app\") == \"api\":
            sys.exit(0)
sys.exit(1)
"'

check "api-policy: ingress from web and egress to db" \
  bash -c '
    kubectl get networkpolicy api-policy -n eda9e0ec987a-network -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
spec = data[\"spec\"]
if spec[\"podSelector\"].get(\"matchLabels\", {}).get(\"app\") != \"api\":
    sys.exit(1)
ing = any(f.get(\"podSelector\", {}).get(\"matchLabels\", {}).get(\"app\") == \"web\"
          for rule in spec.get(\"ingress\", []) for f in rule.get(\"from\", []))
egr = any(t.get(\"podSelector\", {}).get(\"matchLabels\", {}).get(\"app\") == \"db\"
          for rule in spec.get(\"egress\", []) for t in rule.get(\"to\", []))
sys.exit(0 if ing and egr else 1)
"'

check "db-policy: db ingress only from api" \
  bash -c '
    kubectl get networkpolicy db-policy -n eda9e0ec987a-network -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
spec = data[\"spec\"]
if spec[\"podSelector\"].get(\"matchLabels\", {}).get(\"app\") != \"db\":
    sys.exit(1)
if \"Ingress\" not in spec.get(\"policyTypes\", []):
    sys.exit(1)
for rule in spec.get(\"ingress\", []):
    for f in rule.get(\"from\", []):
        if f.get(\"podSelector\", {}).get(\"matchLabels\", {}).get(\"app\") == \"api\":
            sys.exit(0)
sys.exit(1)
"'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
