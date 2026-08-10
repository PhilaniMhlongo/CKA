# Question:
# A node in the cluster has flipped to NotReady following a routine disk cleanup
# that was run on that node.

# Task
# Restore the node to a healthy Ready state.
# When you are finished the node must report Ready in `kubectl get nodes` and the
# kubelet service on that node must be active (running) with no restart loop.
# Do not drain, delete, or re-join the node.

# Video Link - (none)

#Documentation Reference
# Tip: Navigate the documentation manually to build familiarity with its structure
# Tasks -> Debug a Cluster -> Troubleshooting Clusters
# https://kubernetes.io/docs/tasks/debug/debug-cluster/
# Reference -> Setup tools -> kubeadm -> kubeadm init phase
# https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init-phase/
