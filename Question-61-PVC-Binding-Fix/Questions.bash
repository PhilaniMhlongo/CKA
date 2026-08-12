# Question: PVC Binding Failure (Troubleshooting - harder than exam)

# In namespace d8f3b6a1c2e4-storage-fix, the pod data-consumer is stuck
# Pending because its PVC data-claim never binds to the pre-provisioned
# PersistentVolume d8f3b6a1c2e4-data-pv. The claim is wrong in THREE ways.

# Task
# 1. Compare the PVC against the PV and identify every mismatch
#    (storageClassName, accessModes, requested size)
# 2. Fix the PVC so it binds the existing PV.
#    You must NOT modify or recreate the PV.
#    NOTE: those PVC spec fields are immutable, and the PVC is protected
#    while the pod uses it - plan the order of operations carefully.
# 3. End state: data-claim Bound, data-consumer Running with the volume
#    mounted at /data

# Documentation Reference
# Concepts -> Storage -> Persistent Volumes (binding, protection)
# https://kubernetes.io/docs/concepts/storage/persistent-volumes/
