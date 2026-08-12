# Label the namespace with the restricted Pod Security Standard
kubectl label namespace eda9e0ec987a-security pod-security.kubernetes.io/enforce=restricted

# Create the compliant pod
cat <<'EOF' > secure-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
  namespace: eda9e0ec987a-security
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: nginx
      image: nginx
      securityContext:
        allowPrivilegeEscalation: false
        capabilities:
          drop:
            - ALL
EOF
kubectl apply -f secure-pod.yaml

# Verify
kubectl get ns eda9e0ec987a-security --show-labels
kubectl get pod secure-pod -n eda9e0ec987a-security
