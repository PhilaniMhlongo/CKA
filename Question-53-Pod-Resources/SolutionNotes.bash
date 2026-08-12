# Create the pod with resource requests and limits
cat <<'EOF' > resource-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-pod
  namespace: 7b43d4b5300b-monitoring
spec:
  containers:
    - name: nginx
      image: nginx
      resources:
        requests:
          cpu: "100m"
          memory: "128Mi"
        limits:
          cpu: "200m"
          memory: "256Mi"
EOF
kubectl apply -f resource-pod.yaml

# Verify
kubectl get pod resource-pod -n 7b43d4b5300b-monitoring
kubectl get pod resource-pod -n 7b43d4b5300b-monitoring -o jsonpath='{.spec.containers[0].resources}'
