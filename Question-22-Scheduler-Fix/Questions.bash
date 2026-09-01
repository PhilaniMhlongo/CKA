# Question:
# DOMAIN: Troubleshooting
# DISRUPTIVE: kube-scheduler is down until you fix it - nothing else will schedule
# REQUIRES: control-plane node access (kubeadm cluster, e.g. Killercoda)
# A pod named 'stuck-pod' in the 'triage' namespace has been Pending for a long
# time and is never assigned to a node. Other workloads submitted after it are
# also staying Pending.

# Task
# Repair the cluster so that stuck-pod, and any pod created afterwards, is
# scheduled normally.
# When you are finished, stuck-pod must be Running with a node assigned
# (`kubectl get pod stuck-pod -n triage -o wide`) and every control plane
# component in the kube-system namespace must be Running.
# Do not delete stuck-pod or edit its spec.

# Video Link - (none)

#Documentation Reference
# Tip: Navigate the documentation manually to build familiarity with its structure
# Tasks -> Debug a Cluster -> Troubleshooting Clusters
# https://kubernetes.io/docs/tasks/debug/debug-cluster/
