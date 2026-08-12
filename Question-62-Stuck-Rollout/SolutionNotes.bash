# Diagnose - describe shows BOTH: "Insufficient cpu" and
# "node(s) didn't match Pod's node affinity/selector"
kubectl get pods -n d8f3b6a1c2e4-rollout
kubectl describe pod -n d8f3b6a1c2e4-rollout -l app=stuck-app | grep -A5 Events

# Fix 1: cpu request 4 (four full cores) -> 100m
# Fix 2: remove the nodeSelector entirely
kubectl patch deployment stuck-app -n d8f3b6a1c2e4-rollout --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "100m"},
  {"op": "remove", "path": "/spec/template/spec/nodeSelector"}
]'

# Verify
kubectl rollout status deployment/stuck-app -n d8f3b6a1c2e4-rollout --timeout=120s
kubectl get pods -n d8f3b6a1c2e4-rollout -o wide
