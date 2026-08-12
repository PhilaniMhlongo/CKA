# Create the deployment
cat <<'EOF' > app-v1.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-v1
  namespace: eda9e0ec987a-upgrade
spec:
  replicas: 4
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  selector:
    matchLabels:
      app: app-v1
  template:
    metadata:
      labels:
        app: app-v1
    spec:
      containers:
        - name: nginx
          image: nginx:1.19
EOF
kubectl apply -f app-v1.yaml

# Update the image and wait for the rollout
kubectl set image deployment/app-v1 nginx=nginx:1.20 -n eda9e0ec987a-upgrade
kubectl rollout status deployment/app-v1 -n eda9e0ec987a-upgrade

# Save the rollout history
mkdir -p /tmp/exam
kubectl rollout history deployment/app-v1 -n eda9e0ec987a-upgrade > /tmp/exam/rollout-history.txt

# Rollback to nginx:1.19
kubectl rollout undo deployment/app-v1 -n eda9e0ec987a-upgrade

# Verify
kubectl get deployment app-v1 -n eda9e0ec987a-upgrade -o jsonpath='{.spec.template.spec.containers[0].image}'   # nginx:1.19
