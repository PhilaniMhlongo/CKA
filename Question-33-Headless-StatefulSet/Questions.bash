# Question: Headless Service + StatefulSet
# DOMAIN: Storage

# Task
# 1. In namespace eda9e0ec987a-stateful, create a headless Service web-svc
#    (clusterIP: None, selector app=web, port 80)
# 2. Create a StatefulSet web with 3 replicas using nginx and
#    serviceName web-svc
# 3. Add a volumeClaimTemplate named www requesting 1Gi from
#    StorageClass cold, mounted at /usr/share/nginx/html

# Documentation Reference
# Concepts -> Workloads -> Workload Resources -> StatefulSets
# https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/
