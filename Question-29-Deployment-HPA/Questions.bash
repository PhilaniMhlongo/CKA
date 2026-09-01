# Question: Deployment + HPA
# DOMAIN: WorkloadsScheduling

# Task
# 1. Create a deployment named scaling-app in namespace eda9e0ec987a-scaling
#    with 2 replicas using nginx
# 2. Set resource requests cpu: 200m / memory: 256Mi
#    and limits cpu: 500m / memory: 512Mi
# 3. Create an HPA targeting 70% average CPU utilization,
#    with min 2 and max 5 replicas

# Documentation Reference
# Tasks -> Run Applications -> Horizontal Pod Autoscaling Walkthrough
# https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/
