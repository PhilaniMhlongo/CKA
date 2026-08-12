# Create the ServiceAccount
kubectl create serviceaccount app-sa

# Create the Role and RoleBinding
cat <<'EOF' > pod-reader-rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: default
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
  - kind: ServiceAccount
    name: app-sa
    namespace: default
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
EOF
kubectl apply -f pod-reader-rbac.yaml

# Verify
kubectl get sa app-sa
kubectl get role pod-reader
kubectl get rolebinding read-pods
kubectl auth can-i list pods --as=system:serviceaccount:default:app-sa
