# Create the ServiceAccount
kubectl create serviceaccount app-admin -n eda9e0ec987a-cluster-admin

# Create the Role, RoleBinding and pod
cat <<'EOF' > app-admin-rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-admin
  namespace: eda9e0ec987a-cluster-admin
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["list", "get", "watch"]
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["list", "get", "watch", "update"]
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["create", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-admin
  namespace: eda9e0ec987a-cluster-admin
subjects:
  - kind: ServiceAccount
    name: app-admin
    namespace: eda9e0ec987a-cluster-admin
roleRef:
  kind: Role
  name: app-admin
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: v1
kind: Pod
metadata:
  name: admin-pod
  namespace: eda9e0ec987a-cluster-admin
spec:
  serviceAccountName: app-admin
  containers:
    - name: kubectl
      image: bitnami/kubectl:latest
      command: ["sleep", "3600"]
EOF
kubectl apply -f app-admin-rbac.yaml

# Verify
kubectl auth can-i list pods \
  --as=system:serviceaccount:eda9e0ec987a-cluster-admin:app-admin \
  -n eda9e0ec987a-cluster-admin
