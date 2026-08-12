# Bug 1: the service targets port 8080 but nginx listens on 80
kubectl patch service web-svc -n d8f3b6a1c2e4-netpol-debug --type='json' \
  -p='[{"op": "replace", "path": "/spec/ports/0/targetPort", "value": 80}]'

# Bug 2: default-deny-all blocks everything, including the client's DNS lookups.
# Add allow policies on top of it (deny + allow are additive; allow wins).
cat <<'EOF' > netpol-allow.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-web-ingress
  namespace: d8f3b6a1c2e4-netpol-debug
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: client
      ports:
        - protocol: TCP
          port: 80
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-client-egress
  namespace: d8f3b6a1c2e4-netpol-debug
spec:
  podSelector:
    matchLabels:
      app: client
  policyTypes:
    - Egress
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: web
      ports:
        - protocol: TCP
          port: 80
    - to:
        - namespaceSelector: {}
          podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
EOF
kubectl apply -f netpol-allow.yaml

# Verify
kubectl exec client -n d8f3b6a1c2e4-netpol-debug -- curl -s --max-time 5 http://web-svc | head -5
