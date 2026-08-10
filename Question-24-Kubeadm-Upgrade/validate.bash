#!/bin/bash
# Validation script for Question 24 - kubeadm upgrade
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

echo "==========================================="
echo " Validating Question 24: kubeadm upgrade"
echo "==========================================="

WORKDIR="${WORKDIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/upgrade-state}"

if [[ ! -f "$WORKDIR/baseline-version" ]]; then
  echo "  ERROR: no baseline recorded. Run scripts/run-question.sh 24 first."
  exit 1
fi

BASELINE=$(cat "$WORKDIR/baseline-version")
NODE=$(cat "$WORKDIR/controlplane-node")
CURRENT=$(kubectl get node "$NODE" -o jsonpath='{.status.nodeInfo.kubeletVersion}' 2>/dev/null)

echo "  Baseline: $BASELINE   Current: ${CURRENT:-unknown}"
echo ""

# Compare semver-ish version strings without hard-coding any release, so this
# question does not need editing every time upstream cuts a new patch.
version_gt() {
  [[ "$1" != "$2" ]] && [[ "$(printf '%s\n%s\n' "$1" "$2" | sed 's/^v//' | sort -V | tail -1)" == "${1#v}" ]]
}

same_minor() {
  local a="${1#v}" b="${2#v}"
  [[ "${a%.*}" == "${b%.*}" ]]
}

# 1. The kubelet on the controlplane is on a newer version than we started with
check "Controlplane kubelet version is newer than the baseline ($BASELINE)" \
  bash -c "$(declare -f version_gt); version_gt '$CURRENT' '$BASELINE'"

# 2. ...but did not skip a minor release
check "Upgrade stayed within the same minor release (no minor version skip)" \
  bash -c "$(declare -f same_minor); same_minor '$CURRENT' '$BASELINE'"

# 3. Node is Ready
check "Controlplane node is Ready" \
  bash -c '
    STATUS=$(kubectl get node '"$NODE"' -o jsonpath="{.status.conditions[?(@.type==\"Ready\")].status}" 2>/dev/null)
    [[ "$STATUS" == "True" ]]
  '

# 4. Node was uncordoned after the drain
check "Controlplane node is schedulable (uncordoned after drain)" \
  bash -c '
    UNSCHED=$(kubectl get node '"$NODE"' -o jsonpath="{.spec.unschedulable}" 2>/dev/null)
    [[ -z "$UNSCHED" || "$UNSCHED" == "false" ]]
  '

# 5. API server reports the new version too, not just the kubelet
check "API server is running the upgraded version" \
  bash -c "
    SERVER=\$(kubectl version -o json 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin)[\"serverVersion\"][\"gitVersion\"])' 2>/dev/null)
    $(declare -f version_gt)
    version_gt \"\$SERVER\" '$BASELINE'
  "

# 6. Control plane static pods are all back up
for component in kube-apiserver kube-controller-manager kube-scheduler etcd; do
  check "Control plane component '$component' is Running" \
    bash -c "
      kubectl get pods -n kube-system -l component=$component \
        --field-selector=status.phase=Running --no-headers 2>/dev/null | grep -q . ||
      kubectl get pods -n kube-system --no-headers 2>/dev/null |
        grep '^$component' | grep -q Running
    "
done

# 7. The workload survived
check "Workload 'survivor' is still available in upgrade-demo" \
  bash -c '
    AVAIL=$(kubectl get deployment survivor -n upgrade-demo -o jsonpath="{.status.availableReplicas}" 2>/dev/null)
    [[ ${AVAIL:-0} -ge 1 ]]
  '

# 8. kubeadm itself was upgraded alongside (skew check)
check "kubeadm binary matches the upgraded cluster version" \
  bash -c "
    KUBEADM=\$(sudo kubeadm version -o short 2>/dev/null)
    $(declare -f version_gt)
    version_gt \"\$KUBEADM\" '$BASELINE'
  "

echo ""
echo "==========================================="
echo " Summary"
echo "==========================================="
echo "  Passed: $PASS/$TOTAL"
echo "  Failed: $FAIL/$TOTAL"
echo "==========================================="

[[ $FAIL -eq 0 ]] && echo "  Result: SUCCESS" || echo "  Result: FAILURE"
exit $FAIL
