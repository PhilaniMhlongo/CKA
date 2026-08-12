#!/bin/bash
set -e

echo "Creating namespace..."
kubectl create namespace d8f3b6a1c2e4-rbac-debug --dry-run=client -o yaml | kubectl apply -f -

echo "Creating the (broken) RBAC setup..."
kubectl create serviceaccount reporting-sa -n d8f3b6a1c2e4-rbac-debug \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-inspector
  namespace: d8f3b6a1c2e4-rbac-debug
rules:
  - apiGroups: [""]
    resources: ["pod"]
    verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: inspect-pods
  namespace: d8f3b6a1c2e4-rbac-debug
subjects:
  - kind: ServiceAccount
    name: reporting-sa
    namespace: default
roleRef:
  kind: Role
  name: pod-inspector
  apiGroup: rbac.authorization.k8s.io
EOF

echo "[OK] Lab setup complete."
echo "   - Namespace: d8f3b6a1c2e4-rbac-debug"
echo "   - ServiceAccount reporting-sa cannot read pods even though RBAC 'exists'."
