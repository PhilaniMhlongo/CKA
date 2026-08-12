#!/bin/bash
# Cleanup script for Question 55 - Liveness + Readiness Probes
set -uo pipefail
echo "Cleaning up Question 55: Liveness + Readiness Probes..."

kubectl delete pod health-check --ignore-not-found
rm -f health-check.yaml

echo "[OK] Question 55 cleanup complete"
