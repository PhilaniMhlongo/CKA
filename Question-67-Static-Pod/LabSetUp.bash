#!/bin/bash
set -e

if [[ ! -d /etc/kubernetes/manifests ]]; then
  echo "ERROR: /etc/kubernetes/manifests not found."
  echo "This lab must run ON the control-plane node of a kubeadm cluster (e.g. Killercoda)."
  exit 1
fi

echo "[OK] Lab setup complete."
echo "Nothing is pre-created - YOU create the static pod on this node."
