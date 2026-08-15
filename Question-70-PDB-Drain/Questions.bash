# Question: Node Maintenance Blocked by a PDB (Cluster Ops)
# NOTE: needs a cluster with at least 2 schedulable nodes.

# You must take a node down for maintenance. The node runs pods of the
# deployment pdb-app (namespace d8f3b6a1c2e4-pdb-drain), which is guarded
# by the PodDisruptionBudget pdb-app-guard with maxUnavailable: 0 - so
# kubectl drain hangs forever.

# Task
# 1. Reproduce the problem: pick the node running pdb-app pods and try
#      kubectl drain <node> --ignore-daemonsets --delete-emptydir-data --timeout=30s
#    Observe the PDB eviction errors.
# 2. WITHOUT deleting the PDB, change it to maxUnavailable: 1 so one pod
#    may be evicted at a time
# 3. Drain the node successfully and LEAVE it cordoned
# 4. End state: the drained node is SchedulingDisabled, no pdb-app pod runs
#    on it, the PDB still exists with maxUnavailable 1, and the deployment
#    still has available replicas

# Documentation Reference
# Tasks -> Administer a Cluster -> Safely Drain a Node
# https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/
