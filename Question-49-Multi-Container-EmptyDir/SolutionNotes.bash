# Create the multi-container pod
cat <<'EOF' > logger-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: logger
  namespace: 7b43d4b5300b-monitoring
spec:
  containers:
    - name: busybox
      image: busybox
      command: ["/bin/sh", "-c"]
      args:
        - while true; do echo "$(date) - Application log entry" >> /var/log/app.log; sleep 10; done
      volumeMounts:
        - name: log-volume
          mountPath: /var/log
    - name: fluentd
      image: fluentd
      volumeMounts:
        - name: log-volume
          mountPath: /var/log
  volumes:
    - name: log-volume
      emptyDir: {}
EOF
kubectl apply -f logger-pod.yaml

# Verify - the fluentd container sees the log written by busybox
kubectl get pod logger -n 7b43d4b5300b-monitoring
kubectl exec logger -n 7b43d4b5300b-monitoring -c fluentd -- tail /var/log/app.log
