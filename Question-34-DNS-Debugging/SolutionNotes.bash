# Create the deployment, service and debug pod
cat <<'EOF' > dns-debug.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: eda9e0ec987a-dns-debug
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
        - name: nginx
          image: nginx
---
apiVersion: v1
kind: Service
metadata:
  name: web-svc
  namespace: eda9e0ec987a-dns-debug
spec:
  selector:
    app: web-app
  ports:
    - port: 80
      targetPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: dns-test
  namespace: eda9e0ec987a-dns-debug
spec:
  dnsConfig:
    searches:
      - eda9e0ec987a-dns-debug.svc.cluster.local
  containers:
    - name: busybox
      image: busybox
      command: ["sleep", "3600"]
EOF
kubectl apply -f dns-debug.yaml

# Verify DNS resolution from the debug pod
kubectl exec dns-test -n eda9e0ec987a-dns-debug -- nslookup web-svc
kubectl exec dns-test -n eda9e0ec987a-dns-debug -- nslookup web-svc.eda9e0ec987a-dns-debug.svc.cluster.local
