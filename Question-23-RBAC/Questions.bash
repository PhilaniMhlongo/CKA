# Question RBAC
# DOMAIN: ClusterArchitecture

# Context:
# A ServiceAccount named report-runner exists in the finance namespace and is
# used by the reporter Deployment. It currently has no permissions at all.

# Tasks:
# 1. Create a Role named pod-reader in the finance namespace that allows only
#    get, list and watch on pods and configmaps
# 2. Bind that Role to the report-runner ServiceAccount using a RoleBinding
#    named report-runner-read in the finance namespace
# 3. The same ServiceAccount must also be able to list pods in the hr namespace,
#    but must NOT be able to read configmaps there. Grant this without creating a
#    second Role - reuse an existing or newly created cluster-scoped role and
#    bind it only where it is needed
# 4. report-runner must NOT be able to delete pods in any namespace, and must NOT
#    have any permissions outside the finance and hr namespaces

# Verify with:
#   kubectl auth can-i list pods    -n finance --as=system:serviceaccount:finance:report-runner
#   kubectl auth can-i get configmaps -n finance --as=system:serviceaccount:finance:report-runner
#   kubectl auth can-i list pods    -n hr      --as=system:serviceaccount:finance:report-runner
#   kubectl auth can-i get configmaps -n hr    --as=system:serviceaccount:finance:report-runner  # no
#   kubectl auth can-i delete pods  -n finance --as=system:serviceaccount:finance:report-runner  # no

# Video Link - (none)

#Documentation Reference
# Tip: Navigate the documentation manually to build familiarity with its structure
# Reference -> Access Control -> Using RBAC Authorization
# https://kubernetes.io/docs/reference/access-authn-authz/rbac/
