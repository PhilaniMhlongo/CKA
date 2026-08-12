#!/bin/bash
# Validation script for Question 38 - Gateway API
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
echo " Validating Question 38: Gateway API"
echo "============================================"

check "Deployments 'app1' and 'app2' exist" \
  bash -c 'kubectl get deployment app1 app2 -n eda9e0ec987a-gateway'

check "Services 'app1-svc' and 'app2-svc' expose port 8080" \
  bash -c '
    kubectl get svc app1-svc app2-svc -n eda9e0ec987a-gateway -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for svc in data[\"items\"]:
    if not any(p.get(\"port\") == 8080 for p in svc[\"spec\"].get(\"ports\", [])):
        sys.exit(1)
sys.exit(0)
"'

check "Gateway 'main-gateway' has an HTTP listener on port 80" \
  bash -c 'kubectl get gateway main-gateway -n eda9e0ec987a-gateway -o jsonpath="{.spec.listeners[0].protocol}|{.spec.listeners[0].port}" | grep -qx "HTTP|80"'

check "HTTPRoute 'app-routes' is attached to main-gateway" \
  bash -c 'kubectl get httproute app-routes -n eda9e0ec987a-gateway -o jsonpath="{.spec.parentRefs[0].name}" | grep -qx main-gateway'

check "HTTPRoute routes /app1 -> app1-svc:8080 and /app2 -> app2-svc:8080" \
  bash -c '
    kubectl get httproute app-routes -n eda9e0ec987a-gateway -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
wanted = {(\"/app1\", \"app1-svc\", 8080), (\"/app2\", \"app2-svc\", 8080)}
found = set()
for rule in data[\"spec\"].get(\"rules\", []):
    paths = [m.get(\"path\", {}).get(\"value\") for m in rule.get(\"matches\", [])]
    for be in rule.get(\"backendRefs\", []):
        for p in paths:
            found.add((p, be.get(\"name\"), be.get(\"port\")))
sys.exit(0 if wanted.issubset(found) else 1)
"'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
