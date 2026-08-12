#!/bin/bash
# Validation script for Question 58 - NetworkPolicy Connectivity Debug
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
echo " Validating Question 58: NetworkPolicy Connectivity Debug"
echo "============================================"

check "Service targetPort fixed to 80" \
  bash -c 'kubectl get svc web-svc -n d8f3b6a1c2e4-netpol-debug -o jsonpath="{.spec.ports[0].targetPort}" | grep -qx 80'

check "default-deny-all policy still exists" \
  kubectl get networkpolicy default-deny-all -n d8f3b6a1c2e4-netpol-debug

check "An ingress policy allows web from client on TCP 80" \
  bash -c '
    kubectl get networkpolicy -n d8f3b6a1c2e4-netpol-debug -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for pol in data[\"items\"]:
    spec = pol[\"spec\"]
    if spec.get(\"podSelector\", {}).get(\"matchLabels\", {}).get(\"app\") != \"web\":
        continue
    for rule in spec.get(\"ingress\", []) or []:
        from_ok = any(f.get(\"podSelector\", {}).get(\"matchLabels\", {}).get(\"app\") == \"client\"
                      for f in rule.get(\"from\", []))
        port_ok = any(p.get(\"port\") == 80 for p in rule.get(\"ports\", []))
        if from_ok and port_ok:
            sys.exit(0)
sys.exit(1)
"'

check "An egress policy allows client to reach DNS on port 53" \
  bash -c '
    kubectl get networkpolicy -n d8f3b6a1c2e4-netpol-debug -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for pol in data[\"items\"]:
    spec = pol[\"spec\"]
    if spec.get(\"podSelector\", {}).get(\"matchLabels\", {}).get(\"app\") != \"client\":
        continue
    for rule in spec.get(\"egress\", []) or []:
        if any(p.get(\"port\") == 53 for p in rule.get(\"ports\", [])):
            sys.exit(0)
sys.exit(1)
"'

check "client can curl web-svc successfully" \
  kubectl exec client -n d8f3b6a1c2e4-netpol-debug -- curl -s --max-time 5 http://web-svc

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
