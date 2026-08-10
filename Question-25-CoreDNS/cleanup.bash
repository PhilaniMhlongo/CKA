#!/bin/bash
# Cleanup script for Question 25 - CoreDNS
set -uo pipefail
echo "Cleaning up Question 25: CoreDNS..."

WORKDIR="${WORKDIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/coredns-state}"

kubectl delete namespace dns-lab --ignore-not-found

# Restore the original Corefile so a half-finished attempt does not leave cluster
# DNS broken for every other question.
if [[ -f "$WORKDIR/coredns-configmap.bak.yaml" ]]; then
  echo "Restoring the original coredns ConfigMap..."
  kubectl apply -f "$WORKDIR/coredns-configmap.bak.yaml"
  kubectl rollout restart deployment coredns -n kube-system
  kubectl rollout status deployment coredns -n kube-system --timeout=90s || true
else
  echo "WARNING: no Corefile backup found in $WORKDIR."
  echo "Check 'kubectl get configmap coredns -n kube-system -o yaml' by hand."
fi

rm -rf "$WORKDIR"

echo "[OK] Question 25 cleanup complete"
