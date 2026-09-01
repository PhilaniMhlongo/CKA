# Question: Pod Security (restricted)
# DOMAIN: WorkloadsScheduling

# Task
# 1. Label namespace eda9e0ec987a-security with
#    pod-security.kubernetes.io/enforce=restricted
# 2. Create a pod secure-pod in that namespace using nginx that complies
#    with the restricted policy:
#    - runAsNonRoot: true
#    - runAsUser: 1000
#    - seccompProfile type RuntimeDefault
#    - allowPrivilegeEscalation: false
#    - drop ALL capabilities

# NOTE: stock nginx cannot actually serve as UID 1000 (it may CrashLoop);
# the graded check is manifest compliance. In real life you would use
# nginxinc/nginx-unprivileged.

# Documentation Reference
# Concepts -> Security -> Pod Security Standards
# https://kubernetes.io/docs/concepts/security/pod-security-standards/
