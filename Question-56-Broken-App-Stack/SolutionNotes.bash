# Diagnose layer by layer:
kubectl get pods -n d8f3b6a1c2e4-broken-stack               # ImagePullBackOff
kubectl describe pod -n d8f3b6a1c2e4-broken-stack -l app=web-stack | grep -A3 Events
kubectl get endpoints web-stack-svc -n d8f3b6a1c2e4-broken-stack   # <none>

# Bug 1: image nginx:1.99-fake does not exist
# Bug 2: readiness probe hits /healthz which nginx serves as 404 -> never Ready
kubectl patch deployment web-stack -n d8f3b6a1c2e4-broken-stack --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/image", "value": "nginx:1.25"},
  {"op": "replace", "path": "/spec/template/spec/containers/0/readinessProbe/httpGet/path", "value": "/"}
]'

# Bug 3: service selector says app=webstack but pods are labelled app=web-stack
# Bug 4: targetPort 8080 but nginx listens on 80
kubectl patch service web-stack-svc -n d8f3b6a1c2e4-broken-stack --type='json' -p='[
  {"op": "replace", "path": "/spec/selector/app", "value": "web-stack"},
  {"op": "replace", "path": "/spec/ports/0/targetPort", "value": 80}
]'

# Verify
kubectl rollout status deployment/web-stack -n d8f3b6a1c2e4-broken-stack --timeout=120s
kubectl get endpoints web-stack-svc -n d8f3b6a1c2e4-broken-stack   # should list two pod IPs
