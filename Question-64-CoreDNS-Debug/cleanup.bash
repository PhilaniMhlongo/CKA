#!/bin/bash
# Cleanup script for Question 64 - Cluster DNS Outage
set -uo pipefail
echo "Cleaning up Question 64: Cluster DNS Outage..."

WORKDIR="${WORKDIR:-$PWD/coredns-backup}"

# Repair the Corefile in place in case the learner never fixed it
kubectl get configmap coredns -n kube-system -o yaml 2>/dev/null \
  | sed 's/cluster\.broken/cluster.local/g' \
  | kubectl apply -f - 2>/dev/null || true

# Restore the original replica count (default 2 if no backup)
REPLICAS=2
[[ -f "$WORKDIR/coredns-replicas.bak" ]] && REPLICAS=$(cat "$WORKDIR/coredns-replicas.bak")
kubectl scale deployment coredns -n kube-system --replicas="$REPLICAS" 2>/dev/null || true
kubectl rollout restart deployment coredns -n kube-system 2>/dev/null || true

kubectl delete pod dns-client -n d8f3b6a1c2e4-dns-debug --ignore-not-found
kubectl delete namespace d8f3b6a1c2e4-dns-debug --ignore-not-found
rm -rf "$WORKDIR"

echo "[OK] Question 64 cleanup complete (CoreDNS restored)"
