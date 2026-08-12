# Pick a WORKER node (not control-plane) and label it
kubectl get nodes
kubectl label node <NODE_NAME> disk=ssd

# Create the deployment with required node affinity
cat <<'EOF' > app-scheduling.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-scheduling
  namespace: eda9e0ec987a-scheduling
spec:
  replicas: 3
  selector:
    matchLabels:
      app: app-scheduling
  template:
    metadata:
      labels:
        app: app-scheduling
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: disk
                    operator: In
                    values:
                      - ssd
      containers:
        - name: nginx
          image: nginx
EOF
kubectl apply -f app-scheduling.yaml

# Verify all pods landed on the labelled node
kubectl get pods -n eda9e0ec987a-scheduling -o wide
