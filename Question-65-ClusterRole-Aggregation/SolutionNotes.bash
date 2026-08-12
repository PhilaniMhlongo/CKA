# Create the two labelled ClusterRoles and the aggregated one
cat <<'EOF' > monitoring-rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring-pods
  labels:
    rbac.cka.local/aggregate-to-monitoring: "true"
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring-nodes
  labels:
    rbac.cka.local/aggregate-to-monitoring: "true"
rules:
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring-admin
aggregationRule:
  clusterRoleSelectors:
    - matchLabels:
        rbac.cka.local/aggregate-to-monitoring: "true"
rules: []
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: monitoring-admin-binding
subjects:
  - kind: ServiceAccount
    name: monitor-sa
    namespace: d8f3b6a1c2e4-monitoring
roleRef:
  kind: ClusterRole
  name: monitoring-admin
  apiGroup: rbac.authorization.k8s.io
EOF
kubectl create serviceaccount monitor-sa -n d8f3b6a1c2e4-monitoring
kubectl apply -f monitoring-rbac.yaml

# The controller fills in monitoring-admin's rules automatically
kubectl get clusterrole monitoring-admin -o yaml   # rules now contain pods + nodes

# Verify
kubectl auth can-i list nodes --as=system:serviceaccount:d8f3b6a1c2e4-monitoring:monitor-sa      # yes
kubectl auth can-i list pods -A --as=system:serviceaccount:d8f3b6a1c2e4-monitoring:monitor-sa    # yes
kubectl auth can-i list secrets --as=system:serviceaccount:d8f3b6a1c2e4-monitoring:monitor-sa    # no
