# Diagnose:
kubectl get pod log-processor -n d8f3b6a1c2e4-sidecar
kubectl logs log-processor -n d8f3b6a1c2e4-sidecar -c writer   # read-only filesystem errors
kubectl logs log-processor -n d8f3b6a1c2e4-sidecar -c reader   # no such file /logs/app.log
# Bug 1: writer mounts the shared volume readOnly -> cannot write app.log
# Bug 2: reader command reads /logs/... but its mount is at /var/logs

# Pods are immutable here -> recreate with the fixes
kubectl delete pod log-processor -n d8f3b6a1c2e4-sidecar

cat <<'EOF' > log-processor-fixed.yaml
apiVersion: v1
kind: Pod
metadata:
  name: log-processor
  namespace: d8f3b6a1c2e4-sidecar
spec:
  containers:
    - name: writer
      image: busybox:1.36
      command: ["sh", "-c", "while true; do echo \"$(date) log entry\" >> /data/app.log; sleep 5; done"]
      volumeMounts:
        - name: shared
          mountPath: /data
    - name: reader
      image: busybox:1.36
      command: ["sh", "-c", "touch /logs/app.log; tail -f /logs/app.log"]
      volumeMounts:
        - name: shared
          mountPath: /logs
  volumes:
    - name: shared
      emptyDir: {}
EOF
kubectl apply -f log-processor-fixed.yaml

# Verify
kubectl get pod log-processor -n d8f3b6a1c2e4-sidecar          # 2/2 Running
sleep 10
kubectl exec log-processor -n d8f3b6a1c2e4-sidecar -c reader -- tail -3 /logs/app.log
