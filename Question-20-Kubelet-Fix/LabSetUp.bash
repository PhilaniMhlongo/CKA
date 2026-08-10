#!/bin/bash
set -e

# Step 1: Backup the kubelet kubeconfig.
# Kept outside /root and /etc/kubernetes so that listing the obvious directories
# does not hand the learner the answer. cleanup.bash restores from here.
CKA_BACKUP_DIR="${CKA_BACKUP_DIR:-/var/tmp/.cka-backups}"
sudo mkdir -p "$CKA_BACKUP_DIR"
sudo cp /etc/kubernetes/kubelet.conf "$CKA_BACKUP_DIR/kubelet.conf.bak"

# Step 2: Simulate a broken kubelet - the kubeconfig is gone, as it would be after
# a bad disk cleanup. It is removed outright rather than renamed in place, so the
# fix is to regenerate it (kubeadm init phase kubeconfig kubelet) rather than to
# spot a conveniently-named leftover sitting next to it.
sudo rm -f /etc/kubernetes/kubelet.conf

# Step 3: Restart kubelet so it fails to start against the broken config path
sudo systemctl restart kubelet || true

echo "Waiting a few seconds for kubelet to fail and node status to flip..."
sleep 5

echo "Checking kubelet service status..."
sudo systemctl status kubelet --no-pager || true

echo ""
echo "[OK] Lab setup complete. The node should go NotReady shortly."
