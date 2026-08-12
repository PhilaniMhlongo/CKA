# Create the ConfigMap and the pod
cat <<'EOF' > config-pod.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  APP_COLOR: blue
---
apiVersion: v1
kind: Pod
metadata:
  name: config-pod
spec:
  containers:
    - name: nginx
      image: nginx
      volumeMounts:
        - name: config-volume
          mountPath: /etc/config
  volumes:
    - name: config-volume
      configMap:
        name: app-config
EOF
kubectl apply -f config-pod.yaml

# Verify - each key becomes a file in the mount path
kubectl exec config-pod -- cat /etc/config/APP_COLOR    # prints: blue
