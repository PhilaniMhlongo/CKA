# Create the three deployments (kubectl create deployment sets label app=<name>)
kubectl create deployment web --image=nginx -n eda9e0ec987a-network
kubectl create deployment api --image=nginx -n eda9e0ec987a-network
kubectl create deployment db  --image=nginx -n eda9e0ec987a-network

# Create the three tiered NetworkPolicies
cat <<'EOF' > tiered-policies.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-policy
  namespace: eda9e0ec987a-network
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
    - Egress
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: api
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-policy
  namespace: eda9e0ec987a-network
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: web
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: db
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-policy
  namespace: eda9e0ec987a-network
spec:
  podSelector:
    matchLabels:
      app: db
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: api
EOF
kubectl apply -f tiered-policies.yaml

# Verify
kubectl get networkpolicy -n eda9e0ec987a-network
