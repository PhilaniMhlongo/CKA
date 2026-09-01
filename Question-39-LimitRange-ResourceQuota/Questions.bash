# Question: LimitRange + ResourceQuota
# DOMAIN: WorkloadsScheduling

# Task
# 1. Create a LimitRange resource-limits in namespace eda9e0ec987a-limits with:
#    - container defaults: cpu 200m / memory 256Mi
#    - default requests: cpu 100m / memory 128Mi
#    - max limits: cpu 500m / memory 512Mi
# 2. Create ResourceQuota compute-quota with hard limits:
#    cpu=2, memory=2Gi, pods=5
# 3. Create deployment test-limits with 2 replicas using nginx
#    (no explicit resources - the LimitRange defaults should apply)

# Documentation Reference
# Concepts -> Policies -> Limit Ranges / Resource Quotas
# https://kubernetes.io/docs/concepts/policy/limit-range/
# https://kubernetes.io/docs/concepts/policy/resource-quotas/
