#!/bin/bash
# Cleanup script for Question 74 - Manual Scheduling without kube-scheduler
set -uo pipefail
echo "Cleaning up Question 74: Manual Scheduling without kube-scheduler..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKDIR="${WORKDIR:-$SCRIPT_DIR/manual-sched-work}"

kubectl delete pod pinned-pod -n d8f3b6a1c2e4-manual-sched --ignore-not-found
kubectl delete pod orphan-pod -n d8f3b6a1c2e4-manual-sched --ignore-not-found
kubectl delete namespace d8f3b6a1c2e4-manual-sched --ignore-not-found

rm -rf "$WORKDIR"

echo "[OK] Question 74 cleanup complete"
