# Create the NetworkPolicy
cat <<'EOF' > db-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-policy
  namespace: 7b43d4b5300b-networking
spec:
  podSelector:
    matchLabels:
      role: db
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              role: frontend
      ports:
        - protocol: TCP
          port: 3306
EOF
kubectl apply -f db-policy.yaml

# Verify
kubectl get networkpolicy db-policy -n 7b43d4b5300b-networking
kubectl describe networkpolicy db-policy -n 7b43d4b5300b-networking
