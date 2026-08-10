# Confirm the node is NotReady
kubectl get nodes

# Check the kubelet service itself first
sudo systemctl status kubelet --no-pager
sudo journalctl -u kubelet -n 50 --no-pager
# Look for an error like:
#   "failed to load kubeconfig file /etc/kubernetes/kubelet.conf: ... no such file or directory"
#   or repeated "Unable to register node with API server"

# Confirm which files the kubelet expects and which are actually there
sudo cat /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
ls -l /etc/kubernetes/
# /etc/kubernetes/kubelet.conf is gone - the disk cleanup removed it.

# Regenerate the kubelet kubeconfig with kubeadm. This is the real fix: it
# re-issues the file from the cluster CA on this node, no backup required.
sudo kubeadm init phase kubeconfig kubelet

# Restart kubelet and confirm it comes up clean
sudo systemctl restart kubelet
sudo systemctl status kubelet --no-pager
sudo journalctl -u kubelet -n 20 --no-pager

# Confirm the node flips back to Ready
kubectl get nodes -w

# Note: on a worker node the cluster CA key is not present, so `kubeadm init
# phase kubeconfig kubelet` cannot be run there. The equivalent recovery is to
# copy a valid kubelet.conf from the controlplane and correct the user/context,
# or to re-issue the node's credentials from the controlplane.
