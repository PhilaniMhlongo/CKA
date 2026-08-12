#!/bin/bash
# Cleanup script for Question 60 - Broken Controller Manager
set -uo pipefail
echo "Cleaning up Question 60: Broken Controller Manager..."

WORKDIR="${WORKDIR:-$PWD/kcm-backup}"
MANIFEST=/etc/kubernetes/manifests/kube-controller-manager.yaml

# Restore the original manifest if the learner never fixed it
if [[ -f "$WORKDIR/kube-controller-manager.yaml.bak" ]]; then
  echo "Restoring kube-controller-manager manifest from backup..."
  cp "$WORKDIR/kube-controller-manager.yaml.bak" "$MANIFEST"
elif [[ -f "$MANIFEST" ]]; then
  # Fall back to reverting the known breakage in place
  sed -i 's|--kubeconfig=/etc/kubernetes/controller-manager-missing.conf|--kubeconfig=/etc/kubernetes/controller-manager.conf|' "$MANIFEST" || true
fi

kubectl delete deployment kcm-test -n d8f3b6a1c2e4-kcm-fix --ignore-not-found
kubectl delete namespace d8f3b6a1c2e4-kcm-fix --ignore-not-found
rm -rf "$WORKDIR"

echo "[OK] Question 60 cleanup complete"
echo "NOTE: allow ~30s for the kubelet to restart the controller manager."
