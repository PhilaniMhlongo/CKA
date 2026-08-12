# Create the deployment
cat <<'EOF' > resource-consumer.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resource-consumer
  namespace: eda9e0ec987a-monitoring
spec:
  replicas: 3
  selector:
    matchLabels:
      app: resource-consumer
  template:
    metadata:
      labels:
        app: resource-consumer
    spec:
      containers:
        - name: resource-consumer
          image: gcr.io/kubernetes-e2e-test-images/resource-consumer:1.5
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 200m
              memory: 256Mi
EOF
kubectl apply -f resource-consumer.yaml

# Create the HPA
kubectl autoscale deployment resource-consumer -n eda9e0ec987a-monitoring \
  --min=3 --max=6 --cpu-percent=50

# Verify
kubectl get deployment,hpa -n eda9e0ec987a-monitoring
