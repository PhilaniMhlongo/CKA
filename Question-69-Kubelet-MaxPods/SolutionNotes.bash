# 1. Set maxPods in the kubelet config file.
#    If the key exists, change it; otherwise append it.
if grep -q "^maxPods:" /var/lib/kubelet/config.yaml; then
  sed -i 's/^maxPods:.*/maxPods: 40/' /var/lib/kubelet/config.yaml
else
  echo "maxPods: 40" >> /var/lib/kubelet/config.yaml
fi

# 2. Restart the kubelet and check it is healthy
systemctl restart kubelet
systemctl is-active kubelet          # active
journalctl -u kubelet --since "-1 min" | tail -5

# 3. The node re-registers its capacity within ~30s
sleep 30
kubectl get node "$(hostname)" -o jsonpath='{.status.capacity.pods}'   # 40
