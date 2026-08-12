# Create the StorageClass and PVC
cat <<'EOF' > fast-storage.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: 7b43d4b5300b-fast-storage
provisioner: kubernetes.io/no-provisioner
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
  namespace: 7b43d4b5300b-storage
spec:
  storageClassName: 7b43d4b5300b-fast-storage
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF
kubectl apply -f fast-storage.yaml

# Verify (PVC will be Pending - expected with no-provisioner)
kubectl get sc 7b43d4b5300b-fast-storage
kubectl get pvc data-pvc -n 7b43d4b5300b-storage
