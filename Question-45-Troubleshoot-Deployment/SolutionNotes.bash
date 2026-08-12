# Inspect the deployment to spot the three issues
kubectl get pods -n eda9e0ec987a-troubleshoot
kubectl describe deployment failing-app -n eda9e0ec987a-troubleshoot

# Fix all three with a JSON patch
kubectl patch deployment failing-app -n eda9e0ec987a-troubleshoot --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/ports/0/containerPort", "value": 80},
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/limits/memory", "value": "256Mi"},
  {"op": "replace", "path": "/spec/template/spec/containers/0/livenessProbe/httpGet/port", "value": 80}
]'
kubectl rollout status deployment/failing-app -n eda9e0ec987a-troubleshoot --timeout=120s

# Alternative: kubectl edit deployment failing-app -n eda9e0ec987a-troubleshoot
# and change the three values by hand.
