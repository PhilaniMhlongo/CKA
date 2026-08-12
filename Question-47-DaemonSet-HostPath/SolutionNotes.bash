# Create the DaemonSet
cat <<'EOF' > log-collector.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: log-collector
  namespace: 7b43d4b5300b-logging
spec:
  selector:
    matchLabels:
      app: log-collector
  template:
    metadata:
      labels:
        app: log-collector
    spec:
      tolerations:
        - operator: Exists    # tolerates ALL taints
      containers:
        - name: log-collector
          image: busybox:1.36
          command: ["/bin/sh", "-c", "while true; do echo collecting logs from $(hostname); sleep 60; done"]
          volumeMounts:
            - name: host-logs
              mountPath: /host-logs
              readOnly: true
      volumes:
        - name: host-logs
          hostPath:
            path: /var/log
EOF
kubectl apply -f log-collector.yaml

# Verify - one pod per node
kubectl get daemonset log-collector -n 7b43d4b5300b-logging
kubectl get pods -n 7b43d4b5300b-logging -o wide
