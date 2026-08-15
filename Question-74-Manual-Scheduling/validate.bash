#!/bin/bash
# Validation script for Question 74 - Manual Scheduling without kube-scheduler
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKDIR="${WORKDIR:-$SCRIPT_DIR/manual-sched-work}"
NS=d8f3b6a1c2e4-manual-sched

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
echo " Validating Question 74: Manual Scheduling without kube-scheduler"
echo "============================================"

if [[ ! -s "$WORKDIR/target-node.txt" ]]; then
  echo "  ERROR: $WORKDIR/target-node.txt missing - run LabSetUp.bash first."
  exit 1
fi
TARGET_NODE=$(cat "$WORKDIR/target-node.txt")
echo "  (target node: $TARGET_NODE)"

check "Pod 'pinned-pod' is Running" \
  bash -c "kubectl get pod pinned-pod -n $NS -o jsonpath='{.status.phase}' | grep -qx Running"

check "Pod 'pinned-pod' runs on the target node" \
  bash -c "kubectl get pod pinned-pod -n $NS -o jsonpath='{.spec.nodeName}' | grep -qx '$TARGET_NODE'"

check "Pod 'pinned-pod' uses image nginx:1.25" \
  bash -c "kubectl get pod pinned-pod -n $NS -o jsonpath='{.spec.containers[0].image}' | grep -qx 'nginx:1.25'"

check "Pod 'pinned-pod' was placed without scheduler hints (no nodeSelector/affinity)" \
  bash -c "
    kubectl get pod pinned-pod -n $NS -o json 2>/dev/null | python3 -c '
import json, sys
spec = json.load(sys.stdin)[\"spec\"]
sys.exit(1 if spec.get(\"nodeSelector\") or spec.get(\"affinity\") else 0)
'"

check "Pod 'orphan-pod' is now Running" \
  bash -c "kubectl get pod orphan-pod -n $NS -o jsonpath='{.status.phase}' | grep -qx Running"

check "Pod 'orphan-pod' is bound to the target node" \
  bash -c "kubectl get pod orphan-pod -n $NS -o jsonpath='{.spec.nodeName}' | grep -qx '$TARGET_NODE'"

check "Pod 'orphan-pod' still requests schedulerName cka-no-scheduler" \
  bash -c "kubectl get pod orphan-pod -n $NS -o jsonpath='{.spec.schedulerName}' | grep -qx 'cka-no-scheduler'"

if [[ -s "$WORKDIR/orphan-pod.uid" ]]; then
  check "Pod 'orphan-pod' is the original object (bound, not recreated)" \
    bash -c "kubectl get pod orphan-pod -n $NS -o jsonpath='{.metadata.uid}' | grep -qx \"\$(cat '$WORKDIR/orphan-pod.uid')\""
else
  echo "  SKIP: original orphan-pod UID not recorded - cannot prove it was not recreated"
fi

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
