# Question: Rolling Update + Rollback
# DOMAIN: WorkloadsScheduling

# Task
# 1. Create deployment app-v1 in namespace eda9e0ec987a-upgrade with
#    4 replicas using nginx:1.19, RollingUpdate strategy with
#    maxUnavailable=1 and maxSurge=1
# 2. Update the image to nginx:1.20
# 3. Save the rollout history to /tmp/exam/rollout-history.txt
# 4. Rollback to nginx:1.19

# Documentation Reference
# Concepts -> Workloads -> Workload Resources -> Deployments
# https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
