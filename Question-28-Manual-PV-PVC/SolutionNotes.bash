# Find a worker node name first
kubectl get nodes

# Create PV, PVC and pod (replace <NODE_NAME> with an actual worker node name)
cat <<'EOF' > manual-storage.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: eda9e0ec987a-manual-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /mnt/data
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - <NODE_NAME>
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: manual-pvc
  namespace: eda9e0ec987a-manual-storage
spec:
  storageClassName: ""
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: manual-pod
  namespace: eda9e0ec987a-manual-storage
spec:
  containers:
    - name: busybox
      image: busybox
      command: ["sleep", "3600"]
      volumeMounts:
        - name: data-vol
          mountPath: /data
  volumes:
    - name: data-vol
      persistentVolumeClaim:
        claimName: manual-pvc
EOF
kubectl apply -f manual-storage.yaml

# Verify
kubectl get pv eda9e0ec987a-manual-pv
kubectl get pvc manual-pvc -n eda9e0ec987a-manual-storage
kubectl get pod manual-pod -n eda9e0ec987a-manual-storage
