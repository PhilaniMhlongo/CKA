# Question: Resource Consumer + HPA

# Task
# 1. Create deployment resource-consumer in namespace eda9e0ec987a-monitoring
#    with 3 replicas using gcr.io/kubernetes-e2e-test-images/resource-consumer:1.5
# 2. Set requests cpu 100m / memory 128Mi and limits cpu 200m / memory 256Mi
# 3. Create an HPA at 50% CPU utilization, min 3, max 6 replicas

# Documentation Reference
# Tasks -> Run Applications -> Horizontal Pod Autoscaling Walkthrough
# https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/
