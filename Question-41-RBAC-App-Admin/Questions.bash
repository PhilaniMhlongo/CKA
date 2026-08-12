# Question: RBAC (Role / RoleBinding / ServiceAccount)

# Task
# In namespace eda9e0ec987a-cluster-admin:
# 1. Create ServiceAccount app-admin
# 2. Create Role app-admin allowing:
#    - list/get/watch on pods
#    - list/get/watch/update on deployments (apps group)
#    - create/delete on configmaps
# 3. Create RoleBinding app-admin binding the Role to the ServiceAccount
# 4. Create pod admin-pod using bitnami/kubectl:latest with the app-admin
#    ServiceAccount (command: sleep 3600)

# Documentation Reference
# Reference -> Access Authn/Authz -> Using RBAC Authorization
# https://kubernetes.io/docs/reference/access-authn-authz/rbac/
