# Question: Stuck Rollout - Unschedulable Pods (Troubleshooting)

# In namespace d8f3b6a1c2e4-rollout, the deployment stuck-app has been at
# 0/3 for twenty minutes. All pods are Pending. There are TWO independent
# scheduling problems.

# Task
# 1. Use kubectl describe on a Pending pod and read BOTH scheduler messages
# 2. Fix the deployment so all 3 replicas become available:
#    - set the CPU request to 100m (the '4' was a typo for '4 percent')
#    - remove the nodeSelector (no node has that label, and it should not)
# 3. Wait for the rollout to complete

# Documentation Reference
# Tasks -> Monitoring, Logging, and Debugging -> Debug Pods (Pending)
# https://kubernetes.io/docs/tasks/debug/debug-application/debug-pods/
