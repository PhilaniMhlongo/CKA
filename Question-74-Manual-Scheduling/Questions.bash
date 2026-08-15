# Question: Manual Scheduling without kube-scheduler (Workloads & Scheduling)

# Work in namespace d8f3b6a1c2e4-manual-sched. The file
# ./manual-sched-work/target-node.txt (or $WORKDIR/target-node.txt) names the
# node every pod in this task must end up on.

# Task
# 1. Create a pod named pinned-pod using image nginx:1.25 that runs on the
#    target node WITHOUT the scheduler making the placement decision
#    (no nodeSelector, no affinity, no taint/toleration - the pod must
#    already name its node when it is created)
#
# 2. The pod orphan-pod is stuck Pending: it asks for a scheduler named
#    cka-no-scheduler, which does not exist in this cluster, so nothing will
#    ever place it. Get it Running on the same target node using the
#    Kubernetes Binding API.
#    You must NOT delete, recreate, or edit the pod's spec - bind the
#    existing pod object. Its schedulerName must still read cka-no-scheduler
#    when you are done.

# Documentation Reference
# Concepts -> Scheduling, Preemption and Eviction -> Assigning Pods to Nodes
# https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/
# Reference -> Kubernetes API -> Workload Resources -> Binding
# https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/binding-v1/
