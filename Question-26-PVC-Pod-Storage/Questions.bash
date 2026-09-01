# Question: PVC + Pod (Storage)
# DOMAIN: Storage

# Task
# 1. Create a PersistentVolumeClaim named data-pvc in namespace eda9e0ec987a-storage-task
#    using StorageClass standard with 2Gi storage and ReadWriteOnce access mode
# 2. Create a pod named data-pod in the same namespace using the nginx image
#    that mounts the PVC at /usr/share/nginx/html

# Documentation Reference
# Concepts -> Storage -> Persistent Volumes
# https://kubernetes.io/docs/concepts/storage/persistent-volumes/
