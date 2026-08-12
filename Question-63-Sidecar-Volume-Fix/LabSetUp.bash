#!/bin/bash
set -e

echo "Creating namespace..."
kubectl create namespace d8f3b6a1c2e4-sidecar --dry-run=client -o yaml | kubectl apply -f -

echo "Creating the (broken) log-processor pod..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: log-processor
  namespace: d8f3b6a1c2e4-sidecar
spec:
  containers:
    - name: writer
      image: busybox:1.36
      command: ["sh", "-c", "while true; do echo \"\$(date) log entry\" >> /data/app.log; sleep 5; done"]
      volumeMounts:
        - name: shared
          mountPath: /data
          readOnly: true
    - name: reader
      image: busybox:1.36
      command: ["sh", "-c", "cat /logs/app.log && tail -f /logs/app.log"]
      volumeMounts:
        - name: shared
          mountPath: /var/logs
  volumes:
    - name: shared
      emptyDir: {}
EOF

echo "[OK] Lab setup complete."
echo "   - Namespace: d8f3b6a1c2e4-sidecar"
echo "   - Pod log-processor is unhealthy: reader crashloops and no log data flows."
