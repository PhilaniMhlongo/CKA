# Create the deployment with resource requests/limits
cat <<'EOF' > scaling-app.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: scaling-app
  namespace: eda9e0ec987a-scaling
spec:
  replicas: 2
  selector:
    matchLabels:
      app: scaling-app
  template:
    metadata:
      labels:
        app: scaling-app
    spec:
      containers:
        - name: nginx
          image: nginx
          resources:
            requests:
              cpu: 200m
              memory: 256Mi
            limits:
              cpu: 500m
              memory: 512Mi
EOF
kubectl apply -f scaling-app.yaml

# Create the HPA
kubectl autoscale deployment scaling-app -n eda9e0ec987a-scaling \
  --min=2 --max=5 --cpu-percent=70

# Verify
kubectl get deployment scaling-app -n eda9e0ec987a-scaling
kubectl get hpa -n eda9e0ec987a-scaling
