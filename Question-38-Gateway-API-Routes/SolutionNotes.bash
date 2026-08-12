# Check which GatewayClass exists in the cluster first
kubectl get gatewayclass

# Create everything
cat <<'EOF' > gateway-routes.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app1
  namespace: eda9e0ec987a-gateway
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app1
  template:
    metadata:
      labels:
        app: app1
    spec:
      containers:
        - name: nginx
          image: nginx
---
apiVersion: v1
kind: Service
metadata:
  name: app1-svc
  namespace: eda9e0ec987a-gateway
spec:
  selector:
    app: app1
  ports:
    - port: 8080
      targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app2
  namespace: eda9e0ec987a-gateway
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app2
  template:
    metadata:
      labels:
        app: app2
    spec:
      containers:
        - name: nginx
          image: nginx
---
apiVersion: v1
kind: Service
metadata:
  name: app2-svc
  namespace: eda9e0ec987a-gateway
spec:
  selector:
    app: app2
  ports:
    - port: 8080
      targetPort: 80
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: main-gateway
  namespace: eda9e0ec987a-gateway
spec:
  gatewayClassName: example
  listeners:
    - name: http
      protocol: HTTP
      port: 80
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: app-routes
  namespace: eda9e0ec987a-gateway
spec:
  parentRefs:
    - name: main-gateway
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /app1
      backendRefs:
        - name: app1-svc
          port: 8080
    - matches:
        - path:
            type: PathPrefix
            value: /app2
      backendRefs:
        - name: app2-svc
          port: 8080
EOF
kubectl apply -f gateway-routes.yaml

# Verify
kubectl get gateway,httproute -n eda9e0ec987a-gateway
