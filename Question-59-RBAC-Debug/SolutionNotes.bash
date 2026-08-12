# Reproduce the failure
kubectl auth can-i list pods \
  --as=system:serviceaccount:d8f3b6a1c2e4-rbac-debug:reporting-sa \
  -n d8f3b6a1c2e4-rbac-debug          # no

# Inspect the Role: resource is "pod" (must be plural "pods") and verbs
# are missing list/watch
kubectl get role pod-inspector -n d8f3b6a1c2e4-rbac-debug -o yaml

# Inspect the RoleBinding: the subject points at reporting-sa in the
# WRONG namespace (default instead of d8f3b6a1c2e4-rbac-debug)
kubectl get rolebinding inspect-pods -n d8f3b6a1c2e4-rbac-debug -o yaml

# Fix the Role
kubectl patch role pod-inspector -n d8f3b6a1c2e4-rbac-debug --type='json' -p='[
  {"op": "replace", "path": "/rules/0/resources/0", "value": "pods"},
  {"op": "replace", "path": "/rules/0/verbs", "value": ["get", "list", "watch"]}
]'

# Fix the RoleBinding subject namespace
kubectl patch rolebinding inspect-pods -n d8f3b6a1c2e4-rbac-debug --type='json' -p='[
  {"op": "replace", "path": "/subjects/0/namespace", "value": "d8f3b6a1c2e4-rbac-debug"}
]'

# Verify
kubectl auth can-i list pods \
  --as=system:serviceaccount:d8f3b6a1c2e4-rbac-debug:reporting-sa \
  -n d8f3b6a1c2e4-rbac-debug          # yes
kubectl auth can-i delete pods \
  --as=system:serviceaccount:d8f3b6a1c2e4-rbac-debug:reporting-sa \
  -n d8f3b6a1c2e4-rbac-debug          # no
