# Diagnose the mismatch (three differences: class fast vs manual,
# mode ROX vs RWO, size 5Gi vs 1Gi)
kubectl get pv d8f3b6a1c2e4-data-pv
kubectl get pvc data-claim -n d8f3b6a1c2e4-storage-fix -o yaml

# The PVC spec fields are immutable -> the PVC must be recreated.
# But pvc-protection blocks deletion while data-consumer uses it,
# so delete the pod FIRST.
kubectl delete pod data-consumer -n d8f3b6a1c2e4-storage-fix
kubectl delete pvc data-claim -n d8f3b6a1c2e4-storage-fix

# Recreate the PVC to match the PV, then recreate the pod
cat <<'EOF' > q61-fixed.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-claim
  namespace: d8f3b6a1c2e4-storage-fix
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: data-consumer
  namespace: d8f3b6a1c2e4-storage-fix
spec:
  containers:
    - name: busybox
      image: busybox:1.36
      command: ["sleep", "3600"]
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: data-claim
EOF
kubectl apply -f q61-fixed.yaml

# Verify
kubectl get pvc data-claim -n d8f3b6a1c2e4-storage-fix     # Bound
kubectl get pod data-consumer -n d8f3b6a1c2e4-storage-fix  # Running
