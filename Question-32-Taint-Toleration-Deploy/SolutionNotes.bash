# Pick a worker node and taint it
kubectl get nodes
kubectl taint nodes <NODE_NAME> special-workload=true:NoSchedule

# Create both deployments
cat <<'EOF' > taint-toleration.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: toleration-deploy
  namespace: eda9e0ec987a-scheduling
spec:
  replicas: 2
  selector:
    matchLabels:
      app: toleration-deploy
  template:
    metadata:
      labels:
        app: toleration-deploy
    spec:
      tolerations:
        - key: special-workload
          operator: Equal
          value: "true"
          effect: NoSchedule
      containers:
        - name: nginx
          image: nginx
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: normal-deploy
  namespace: eda9e0ec987a-scheduling
spec:
  replicas: 2
  selector:
    matchLabels:
      app: normal-deploy
  template:
    metadata:
      labels:
        app: normal-deploy
    spec:
      containers:
        - name: nginx
          image: nginx
EOF
kubectl apply -f taint-toleration.yaml

# Verify placement (normal-deploy pods must avoid the tainted node)
kubectl get pods -n eda9e0ec987a-scheduling -o wide
