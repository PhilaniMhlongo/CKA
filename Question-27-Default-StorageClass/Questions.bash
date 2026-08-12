# Question: Default StorageClass

# Task
# 1. Create a StorageClass named eda9e0ec987a-fast-local with:
#    - provisioner: rancher.io/local-path
#    - volumeBindingMode: WaitForFirstConsumer
# 2. Set it as the default StorageClass by adding the annotation
#    storageclass.kubernetes.io/is-default-class=true

# Documentation Reference
# Tasks -> Administer a Cluster -> Change the default StorageClass
# https://kubernetes.io/docs/tasks/administer-cluster/change-default-storage-class/
