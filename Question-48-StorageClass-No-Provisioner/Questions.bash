# Question: StorageClass + PVC (no-provisioner)

# Task
# 1. Create a StorageClass 7b43d4b5300b-fast-storage with provisioner
#    kubernetes.io/no-provisioner
# 2. Create a PVC data-pvc in namespace 7b43d4b5300b-storage using that
#    StorageClass, requesting 1Gi with ReadWriteOnce

# NOTE: with no-provisioner the PVC stays Pending until a matching PV
# exists - that is expected.

# Documentation Reference
# Concepts -> Storage -> Storage Classes
# https://kubernetes.io/docs/concepts/storage/storage-classes/
