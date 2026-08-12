#!/bin/bash
# Validation script for Question 47 - DaemonSet with hostPath
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
echo " Validating Question 47: DaemonSet with hostPath"
echo "============================================"

check "DaemonSet 'log-collector' exists and uses busybox:1.36" \
  bash -c 'kubectl get daemonset log-collector -n 7b43d4b5300b-logging -o jsonpath="{.spec.template.spec.containers[0].image}" | grep -qx "busybox:1.36"'

check "DaemonSet tolerates all taints (operator Exists with no key)" \
  bash -c '
    kubectl get daemonset log-collector -n 7b43d4b5300b-logging -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for t in data[\"spec\"][\"template\"][\"spec\"].get(\"tolerations\", []) or []:
    if t.get(\"operator\") == \"Exists\" and not t.get(\"key\"):
        sys.exit(0)
sys.exit(1)
"'

check "Volume 'host-logs' uses hostPath /var/log" \
  bash -c '
    kubectl get daemonset log-collector -n 7b43d4b5300b-logging -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for v in data[\"spec\"][\"template\"][\"spec\"].get(\"volumes\", []):
    if v[\"name\"] == \"host-logs\" and v.get(\"hostPath\", {}).get(\"path\") == \"/var/log\":
        sys.exit(0)
sys.exit(1)
"'

check "Volume is mounted read-only at /host-logs" \
  bash -c '
    kubectl get daemonset log-collector -n 7b43d4b5300b-logging -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for c in data[\"spec\"][\"template\"][\"spec\"][\"containers\"]:
    for m in c.get(\"volumeMounts\", []):
        if m[\"name\"] == \"host-logs\" and m[\"mountPath\"] == \"/host-logs\" and m.get(\"readOnly\") is True:
            sys.exit(0)
sys.exit(1)
"'

check "DaemonSet is scheduled on every node" \
  bash -c 'DESIRED=$(kubectl get daemonset log-collector -n 7b43d4b5300b-logging -o jsonpath="{.status.desiredNumberScheduled}"); NODES=$(kubectl get nodes --no-headers | wc -l); [[ -n "$DESIRED" && "$DESIRED" -eq "$NODES" ]]'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
