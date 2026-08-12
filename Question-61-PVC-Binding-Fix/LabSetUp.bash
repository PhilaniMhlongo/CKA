#!/bin/bash
set -e

echo "Creating namespace..."
kubectl create namespace d8f3b6a1c2e4-storage-fix --dry-run=client -o yaml | kubectl apply -f -

echo "Creating PV, mismatched PVC and a stuck pod..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: d8f3b6a1c2e4-data-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: manual
  hostPath:
    path: /mnt/q61-data
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-claim
  namespace: d8f3b6a1c2e4-storage-fix
spec:
  storageClassName: fast
  accessModes:
    - ReadOnlyMany
  resources:
    requests:
      storage: 5Gi
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

echo "[OK] Lab setup complete."
echo "   - Namespace: d8f3b6a1c2e4-storage-fix"
echo "   - PVC 'data-claim' is Pending and pod 'data-consumer' cannot start."
