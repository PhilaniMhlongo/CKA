# Question: Cluster upgrade with kubeadm
# DOMAIN: ClusterArchitecture
# DISRUPTIVE: drains the controlplane and restarts control plane components
# REQUIRES: control-plane node access (kubeadm cluster, e.g. Killercoda)

# Context:
# The controlplane node is running an older patch release than the rest of the
# cluster should be on. A workload is running that must not be disrupted more
# than necessary.

# Tasks:
# 1. Determine which versions the cluster can be upgraded to
# 2. Upgrade the controlplane node's control plane components to the next
#    available patch version of the minor release it is already on
#    (do not jump a minor version)
# 3. Upgrade kubelet and kubectl on the controlplane node to the same version
# 4. Drain the controlplane node before upgrading the kubelet and uncordon it
#    afterwards, so the node ends up schedulable again
# 5. Leave every control plane component Running and the node Ready

# Notes:
# - Upgrade one minor version at a time. kubeadm refuses to skip minor versions.
# - The kubeadm binary must be upgraded first, before `kubeadm upgrade apply`.
# - Check the version skew policy: kubelet may trail the API server, never lead it.

# Verify with:
#   kubectl get nodes            # controlplane Ready, at the new version
#   kubectl get pods -n kube-system
#   kubeadm version

# Video Link - (none)

#Documentation Reference
# Tip: Navigate the documentation manually to build familiarity with its structure
# Tasks -> Administer a Cluster -> Upgrade A Cluster
# https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/
# Setup -> Best practices -> Version Skew Policy
# https://kubernetes.io/releases/version-skew-policy/
