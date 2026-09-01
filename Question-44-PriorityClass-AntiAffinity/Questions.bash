# Question: PriorityClasses + Pod Anti-Affinity
# DOMAIN: WorkloadsScheduling

# Task
# 1. Create PriorityClasses:
#    - eda9e0ec987a-high-priority (value 1000)
#    - eda9e0ec987a-low-priority (value 100)
#    both with globalDefault false and preemptionPolicy PreemptLowerPriority
# 2. Create pods high-priority and low-priority in namespace
#    eda9e0ec987a-scheduling using nginx with the matching priorityClassName
# 3. Give each pod required podAntiAffinity so they never land on the
#    same node (use labels and topologyKey kubernetes.io/hostname)

# Documentation Reference
# Concepts -> Scheduling and Eviction -> Pod Priority and Preemption
# https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/
