# Create the pod with liveness and readiness probes
cat <<'EOF' > health-check.yaml
apiVersion: v1
kind: Pod
metadata:
  name: health-check
spec:
  containers:
    - name: nginx
      image: nginx
      livenessProbe:
        httpGet:
          path: /
          port: 80
        initialDelaySeconds: 5
      readinessProbe:
        httpGet:
          path: /
          port: 80
        initialDelaySeconds: 5
EOF
kubectl apply -f health-check.yaml

# Verify
kubectl get pod health-check
kubectl describe pod health-check | grep -A2 -E "Liveness|Readiness"
