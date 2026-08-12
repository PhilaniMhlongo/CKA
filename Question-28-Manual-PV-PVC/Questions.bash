# Question: Manual PV / PVC / Pod

# Task
# 1. Create a PersistentVolume named eda9e0ec987a-manual-pv with:
#    - 1Gi capacity, ReadWriteOnce access mode
#    - hostPath /mnt/data
#    - nodeAffinity matching any one worker node (kubernetes.io/hostname)
# 2. Create a PersistentVolumeClaim named manual-pvc in namespace
#    eda9e0ec987a-manual-storage with storageClassName set to the EMPTY STRING
#    ("") requesting 1Gi
# 3. Create a pod named manual-pod using busybox (command: sleep 3600)
#    that mounts the PVC at /data

# Documentation Reference
# Tasks -> Configure Pods and Containers -> Configure a Pod to Use a PersistentVolume
# https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/
