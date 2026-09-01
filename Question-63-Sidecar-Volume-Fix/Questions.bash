# Question: Broken Sidecar Volume Sharing (Troubleshooting)
# DOMAIN: Troubleshooting

# In namespace d8f3b6a1c2e4-sidecar, the pod log-processor has a writer
# container that should append to app.log and a reader sidecar that should
# tail the same file through a shared emptyDir. Instead, the reader is in
# CrashLoopBackOff and no log data ever appears. There are TWO bugs.

# Task
# 1. Diagnose both problems (kubectl describe + kubectl logs per container)
# 2. Fix the pod so that:
#    - writer writes to /data/app.log (its mount must be writable)
#    - reader tails the same file via ITS mount at /logs (mount path and
#      command must agree)
#    NOTE: pod container specs are immutable - you must recreate the pod.
# 3. End state: pod Running with 2/2 ready and app.log growing.

# Documentation Reference
# Concepts -> Workloads -> Pods (multi-container patterns)
# https://kubernetes.io/docs/concepts/workloads/pods/
