# Create the headless service and the StatefulSet
cat <<'EOF' > web-statefulset.yaml
apiVersion: v1
kind: Service
metadata:
  name: web-svc
  namespace: eda9e0ec987a-stateful
spec:
  clusterIP: None
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
  namespace: eda9e0ec987a-stateful
spec:
  replicas: 3
  serviceName: web-svc
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
          volumeMounts:
            - name: www
              mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
    - metadata:
        name: www
      spec:
        storageClassName: cold
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 1Gi
EOF
kubectl apply -f web-statefulset.yaml

# Verify the service is headless
kubectl get svc web-svc -n eda9e0ec987a-stateful -o jsonpath='{.spec.clusterIP}'   # should print None
kubectl get statefulset web -n eda9e0ec987a-stateful
