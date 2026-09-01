# Question: Taints & Tolerations
# DOMAIN: WorkloadsScheduling

# Task
# 1. Taint any worker node with special-workload=true:NoSchedule
# 2. Create deployment toleration-deploy (2 replicas, nginx) in namespace
#    eda9e0ec987a-scheduling with a toleration matching the taint
# 3. Create deployment normal-deploy (2 replicas, nginx) in the same
#    namespace WITHOUT a toleration
# 4. Verify normal-deploy pods do not schedule on the tainted node

# Documentation Reference
# Concepts -> Scheduling and Eviction -> Taints and Tolerations
# https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/
