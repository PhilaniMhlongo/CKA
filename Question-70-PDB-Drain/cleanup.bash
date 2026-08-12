#!/bin/bash
# Cleanup script for Question 70 - Node Maintenance Blocked by a PDB
set -uo pipefail
echo "Cleaning up Question 70: Node Maintenance Blocked by a PDB..."

kubectl delete pdb pdb-app-guard -n d8f3b6a1c2e4-pdb-drain --ignore-not-found
kubectl delete deployment pdb-app -n d8f3b6a1c2e4-pdb-drain --ignore-not-found
kubectl delete namespace d8f3b6a1c2e4-pdb-drain --ignore-not-found

echo "Uncordoning all nodes..."
for node in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
  kubectl uncordon "$node" >/dev/null 2>&1 || true
done
rm -f /tmp/q70-pods.json

echo "[OK] Question 70 cleanup complete"
