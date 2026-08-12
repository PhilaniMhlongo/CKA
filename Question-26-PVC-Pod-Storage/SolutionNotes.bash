# Create the PVC and the pod that mounts it
cat <<'EOF' > pvc-pod.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
  namespace: eda9e0ec987a-storage-task
spec:
  storageClassName: standard
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: data-pod
  namespace: eda9e0ec987a-storage-task
spec:
  containers:
    - name: nginx
      image: nginx
      volumeMounts:
        - name: data-volume
          mountPath: /usr/share/nginx/html
  volumes:
    - name: data-volume
      persistentVolumeClaim:
        claimName: data-pvc
EOF
kubectl apply -f pvc-pod.yaml

# Verify
kubectl get pvc data-pvc -n eda9e0ec987a-storage-task
kubectl get pod data-pod -n eda9e0ec987a-storage-task
