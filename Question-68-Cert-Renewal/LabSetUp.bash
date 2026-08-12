#!/bin/bash
set -e

if ! command -v kubeadm >/dev/null 2>&1 || [[ ! -f /etc/kubernetes/pki/apiserver.crt ]]; then
  echo "ERROR: kubeadm and /etc/kubernetes/pki/apiserver.crt are required."
  echo "This lab must run ON the control-plane node of a kubeadm cluster (e.g. Killercoda)."
  exit 1
fi

mkdir -p /tmp/exam

echo "[OK] Lab setup complete."
echo "Nothing is broken - this is a certificate-management operations task."
