#!/bin/bash
# Cleanup script for Question 68 - kubeadm Certificate Renewal
set -uo pipefail
echo "Cleaning up Question 68: kubeadm Certificate Renewal..."

rm -f /tmp/exam/cert-expiration-before.txt /tmp/exam/cert-expiration-after.txt
rmdir /tmp/exam 2>/dev/null || true

echo "[OK] Question 68 cleanup complete"
echo "NOTE: the renewed apiserver certificate is intentionally left in place."
