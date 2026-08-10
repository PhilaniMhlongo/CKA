# Order matters here: kubeadm first, then the control plane, then the kubelet.

# Step 0 - what version are we on, and what can we go to?
kubectl get nodes
sudo kubeadm version
sudo kubeadm upgrade plan
# The plan output lists the target patch version for the current minor release.
# Pick the next PATCH version, e.g. v1.32.1 -> v1.32.2. Do not jump minors.

TARGET=v1.32.2   # replace with what `kubeadm upgrade plan` actually offers

# Step 1 - the package repo is pinned per minor version. If you are staying on
# the same minor release you do not need to touch it; if you were crossing a
# minor boundary you would first update the version in:
#   /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update

# Step 2 - upgrade the kubeadm binary itself, unhold then re-hold
sudo apt-mark unhold kubeadm
sudo apt-get install -y kubeadm=${TARGET#v}-1.1
sudo apt-mark hold kubeadm
sudo kubeadm version   # confirm before continuing

# Step 3 - upgrade the control plane components on this node
sudo kubeadm upgrade apply "$TARGET" -y
# On a SECOND control plane node you would instead run:
#   sudo kubeadm upgrade node

# Step 4 - drain before touching the kubelet. --ignore-daemonsets is required
# because DaemonSet pods cannot be evicted; they are restarted in place.
kubectl drain <controlplane-node> --ignore-daemonsets

# Step 5 - upgrade kubelet and kubectl, then restart the kubelet
sudo apt-mark unhold kubelet kubectl
sudo apt-get install -y kubelet=${TARGET#v}-1.1 kubectl=${TARGET#v}-1.1
sudo apt-mark hold kubelet kubectl
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Step 6 - put the node back into service. Forgetting this is the single most
# common way to lose the marks on this question.
kubectl uncordon <controlplane-node>

# Step 7 - verify
kubectl get nodes                    # Ready, new version, not SchedulingDisabled
kubectl get pods -n kube-system
kubectl version

# Note on skew: kubelet may be up to 3 minor versions behind the API server, but
# must never be ahead of it. That is why the control plane is upgraded first.
