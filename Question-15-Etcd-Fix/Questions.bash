# Question:
# DOMAIN: Troubleshooting
# DISRUPTIVE: kube-apiserver is down until you fix it - blocks all other work
# REQUIRES: control-plane node access (kubeadm cluster, e.g. Killercoda)
# A cluster migration has just been completed. Before the migration etcd ran
# externally in an HA configuration; the kube-apiserver on the controlplane node
# has not come back up since.

# Task
# Repair the controlplane so that the kube-apiserver is running and healthy.
# When you are finished, `kubectl get nodes` must succeed and every control plane
# component in the kube-system namespace must be Running.
# Do not change the etcd configuration itself - only the controlplane node is
# misconfigured.

# Video Link - https://youtu.be/IL448T6r8H4

#Documentation Reference
# Tip: Navigate the documentation manually to build familiarity with its structure
# Tasks -> Debug a Cluster -> Troubleshooting Clusters
# https://kubernetes.io/docs/tasks/debug/debug-cluster/
