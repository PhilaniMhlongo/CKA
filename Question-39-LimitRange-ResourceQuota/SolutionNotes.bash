# Create the LimitRange, ResourceQuota and deployment
cat <<'EOF' > limits.yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: resource-limits
  namespace: eda9e0ec987a-limits
spec:
  limits:
    - type: Container
      default:
        cpu: 200m
        memory: 256Mi
      defaultRequest:
        cpu: 100m
        memory: 128Mi
      max:
        cpu: 500m
        memory: 512Mi
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: eda9e0ec987a-limits
spec:
  hard:
    cpu: "2"
    memory: 2Gi
    pods: "5"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-limits
  namespace: eda9e0ec987a-limits
spec:
  replicas: 2
  selector:
    matchLabels:
      app: test-limits
  template:
    metadata:
      labels:
        app: test-limits
    spec:
      containers:
        - name: nginx
          image: nginx
EOF
kubectl apply -f limits.yaml

# Verify - pods should have inherited the LimitRange defaults
kubectl describe limitrange resource-limits -n eda9e0ec987a-limits
kubectl get pods -n eda9e0ec987a-limits -o jsonpath='{.items[0].spec.containers[0].resources}'
