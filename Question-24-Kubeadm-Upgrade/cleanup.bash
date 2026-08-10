#!/bin/bash
# Cleanup script for Question 24 - kubeadm upgrade
set -uo pipefail
echo "Cleaning up Question 24: kubeadm upgrade..."

WORKDIR="${WORKDIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/upgrade-state}"

kubectl delete namespace upgrade-demo --ignore-not-found

# Make sure the lab does not leave the controlplane cordoned if the learner
# drained it and stopped there.
if [[ -f "$WORKDIR/controlplane-node" ]]; then
  NODE=$(cat "$WORKDIR/controlplane-node")
  UNSCHED=$(kubectl get node "$NODE" -o jsonpath='{.spec.unschedulable}' 2>/dev/null)
  if [[ "$UNSCHED" == "true" ]]; then
    echo "Node $NODE is still cordoned, uncordoning it."
    kubectl uncordon "$NODE"
  fi
fi

rm -rf "$WORKDIR"

echo "NOTE: an actual version upgrade is not reverted by this script."
echo "[OK] Question 24 cleanup complete"
