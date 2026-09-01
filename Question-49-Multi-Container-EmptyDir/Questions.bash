# Question: Multi-Container Pod (shared emptyDir)
# DOMAIN: WorkloadsScheduling

# Task
# Create a pod logger in namespace 7b43d4b5300b-monitoring with two
# containers sharing an emptyDir volume:
# 1. A busybox container writing timestamped log entries to
#    /var/log/app.log every 10 seconds
# 2. A fluentd container reading from the same location

# Documentation Reference
# Concepts -> Storage -> Volumes (emptyDir)
# https://kubernetes.io/docs/concepts/storage/volumes/#emptydir
