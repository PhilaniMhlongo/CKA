#!/bin/bash
set -e

echo "Creating namespace..."
kubectl create namespace d8f3b6a1c2e4-netpol-debug --dry-run=client -o yaml | kubectl apply -f -

echo "Deploying web app, broken service, client pod and a default-deny policy..."
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: d8f3b6a1c2e4-netpol-debug
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: nginx
          image: nginx
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: web-svc
  namespace: d8f3b6a1c2e4-netpol-debug
spec:
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 8080
---
apiVersion: v1
kind: Pod
metadata:
  name: client
  namespace: d8f3b6a1c2e4-netpol-debug
  labels:
    app: client
spec:
  containers:
    - name: curl
      image: curlimages/curl
      command: ["sleep", "3600"]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: d8f3b6a1c2e4-netpol-debug
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
EOF

echo "[OK] Lab setup complete."
echo "   - Namespace: d8f3b6a1c2e4-netpol-debug"
echo "   - 'client' cannot reach 'web-svc'. There is more than one reason."
echo "NOTE: NetworkPolicy enforcement requires a CNI that supports it (Calico/Cilium)."
