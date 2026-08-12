# Question: DaemonSet with hostPath + Tolerate All Taints

# Task
# In namespace 7b43d4b5300b-logging, create a DaemonSet log-collector:
# 1. Image busybox:1.36 running:
#    while true; do echo collecting logs from $(hostname); sleep 60; done
# 2. Mount host path /var/log as volume host-logs at /host-logs (readOnly)
# 3. Tolerate ALL taints so it runs on every node (operator: Exists)

# Documentation Reference
# Concepts -> Workloads -> Workload Resources -> DaemonSet
# https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/
