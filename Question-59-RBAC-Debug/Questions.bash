# Question: RBAC Debugging (Troubleshooting)
# DOMAIN: Troubleshooting

# A monitoring tool runs as ServiceAccount reporting-sa in namespace
# d8f3b6a1c2e4-rbac-debug. It should be able to get, list and watch pods
# in that namespace, but every request is denied - even though a Role and
# RoleBinding were already created. There are MULTIPLE mistakes.

# Task
# 1. Find every mistake in the existing Role/RoleBinding
# 2. Fix them so that:
#      kubectl auth can-i list pods \
#        --as=system:serviceaccount:d8f3b6a1c2e4-rbac-debug:reporting-sa \
#        -n d8f3b6a1c2e4-rbac-debug
#    returns yes (also for get and watch)
# 3. The SA must NOT gain any other permissions (no delete, no secrets)

# Documentation Reference
# Reference -> Access Authn/Authz -> Using RBAC Authorization
# https://kubernetes.io/docs/reference/access-authn-authz/rbac/
