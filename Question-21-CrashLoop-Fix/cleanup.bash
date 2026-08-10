#!/bin/bash
# Cleanup script for Question 21 - CrashLoop Fix
set -uo pipefail
echo "Cleaning up Question 21: CrashLoop Fix..."

kubectl delete namespace shopping --ignore-not-found

echo "[OK] Question 21 cleanup complete"
