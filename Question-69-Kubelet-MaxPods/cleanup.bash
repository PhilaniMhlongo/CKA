#!/bin/bash
# Cleanup script for Question 69 - Kubelet maxPods
set -uo pipefail
echo "Cleaning up Question 69: Kubelet maxPods..."

WORKDIR="${WORKDIR:-$PWD/kubelet-backup}"
CONFIG=/var/lib/kubelet/config.yaml

if [[ -f "$WORKDIR/kubelet-config.yaml.bak" ]]; then
  echo "Restoring the original kubelet config and restarting the kubelet..."
  cp "$WORKDIR/kubelet-config.yaml.bak" "$CONFIG"
  systemctl restart kubelet 2>/dev/null || true
fi
rm -rf "$WORKDIR"

echo "[OK] Question 69 cleanup complete"
