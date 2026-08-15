# Question: Broken App Stack (Troubleshooting)

# In namespace d8f3b6a1c2e4-broken-stack, the deployment web-stack and its
# service web-stack-svc were rolled out, but users report the app is
# completely unreachable. There are FOUR distinct problems across the
# deployment and the service.

# Task
# Find and fix ALL of them so that:
#   1. The deployment has 2 ready replicas (use a real nginx image, e.g. nginx:1.25)
#   2. The service has healthy endpoints
# Do not delete the deployment or the service - fix them in place.

# Documentation Reference
# Tasks -> Monitoring, Logging, and Debugging -> Debug Services
# https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/
