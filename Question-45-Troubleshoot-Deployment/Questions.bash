# Question: Troubleshoot a Broken Deployment
# DOMAIN: Troubleshooting

# In namespace eda9e0ec987a-troubleshoot, the deployment failing-app has
# three issues:
#   1. containerPort is 8080 instead of 80
#   2. memory limit is too low at 32Mi
#   3. the liveness probe points to port 8080

# Task
# Fix all three issues:
#   - containerPort 80
#   - memory limit 256Mi
#   - liveness probe port 80
# Then make sure the deployment rolls out successfully.

# Documentation Reference
# Tasks -> Monitoring, Logging, and Debugging -> Debug a Deployment
# https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/
