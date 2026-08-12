# Create the deployment, service and dns-tester pod
cat <<'EOF' > dns-config.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dns-app
  namespace: eda9e0ec987a-dns-config
spec:
  replicas: 2
  selector:
    matchLabels:
      app: dns-app
  template:
    metadata:
      labels:
        app: dns-app
    spec:
      containers:
        - name: nginx
          image: nginx
---
apiVersion: v1
kind: Service
metadata:
  name: dns-svc
  namespace: eda9e0ec987a-dns-config
spec:
  selector:
    app: dns-app
  ports:
    - port: 80
      targetPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: dns-tester
  namespace: eda9e0ec987a-dns-config
spec:
  containers:
    - name: dnstools
      image: infoblox/dnstools
      command:
        - sh
        - -c
        - "nslookup dns-svc > /tmp/dns-test.txt && nslookup dns-svc.eda9e0ec987a-dns-config.svc.cluster.local >> /tmp/dns-test.txt && sleep 3600"
EOF
kubectl apply -f dns-config.yaml

# Verify the results file
kubectl exec dns-tester -n eda9e0ec987a-dns-config -- cat /tmp/dns-test.txt
