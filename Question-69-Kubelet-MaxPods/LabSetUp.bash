#!/bin/bash
set -e

CONFIG=/var/lib/kubelet/config.yaml
if [[ ! -f "$CONFIG" ]]; then
  echo "ERROR: $CONFIG not found."
  echo "This lab must run ON a cluster node with kubelet configured by kubeadm (e.g. Killercoda)."
  exit 1
fi

WORKDIR="${WORKDIR:-$PWD/kubelet-backup}"
mkdir -p "$WORKDIR"

echo "Backing up the kubelet config to $WORKDIR ..."
cp "$CONFIG" "$WORKDIR/kubelet-config.yaml.bak"

echo "[OK] Lab setup complete."
echo "Nothing is broken - this is a node configuration task."
echo "A backup of $CONFIG is in $WORKDIR."
