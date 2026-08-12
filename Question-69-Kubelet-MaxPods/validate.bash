#!/bin/bash
# Validation script for Question 69 - Kubelet maxPods
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
echo " Validating Question 69: Kubelet maxPods"
echo "============================================"

check "kubelet config file sets maxPods: 40" \
  bash -c 'grep -Eq "^maxPods:[[:space:]]*40[[:space:]]*$" /var/lib/kubelet/config.yaml'

check "kubelet service is active" \
  bash -c 'systemctl is-active kubelet | grep -qx active'

check "A node advertises pod capacity 40" \
  bash -c '
    kubectl get nodes -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for node in data[\"items\"]:
    if node[\"status\"].get(\"capacity\", {}).get(\"pods\") == \"40\":
        sys.exit(0)
sys.exit(1)
"'

check "All nodes are Ready (restart did not break the node)" \
  bash -c '! kubectl get nodes --no-headers 2>/dev/null | grep -v " Ready" | grep -q .'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
