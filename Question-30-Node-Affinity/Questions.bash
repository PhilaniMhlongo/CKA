# Question: Node Affinity

# Task
# 1. Label any worker node with disk=ssd
# 2. Create a deployment app-scheduling in namespace eda9e0ec987a-scheduling
#    with 3 replicas using nginx
# 3. The pod template must use requiredDuringSchedulingIgnoredDuringExecution
#    node affinity for disk=ssd

# Documentation Reference
# Concepts -> Scheduling and Eviction -> Assigning Pods to Nodes
# https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/
