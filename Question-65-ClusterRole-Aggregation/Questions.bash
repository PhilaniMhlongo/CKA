# Question: ClusterRole Aggregation (Cluster Architecture)

# Task
# 1. Create ClusterRole monitoring-pods with label
#    rbac.cka.local/aggregate-to-monitoring: "true"
#    allowing get/list/watch on pods
# 2. Create ClusterRole monitoring-nodes with the SAME label
#    allowing get/list/watch on nodes
# 3. Create ClusterRole monitoring-admin with NO inline rules, but with an
#    aggregationRule that selects that label - the control plane will fill
#    in its rules automatically
# 4. Create ServiceAccount monitor-sa in namespace d8f3b6a1c2e4-monitoring
#    and a ClusterRoleBinding monitoring-admin-binding granting it
#    monitoring-admin
# 5. Verify: the SA can list nodes and pods cluster-wide, but NOT secrets

# Documentation Reference
# Reference -> Access Authn/Authz -> Using RBAC Authorization (Aggregated ClusterRoles)
# https://kubernetes.io/docs/reference/access-authn-authz/rbac/#aggregated-clusterroles
