# Diagnose - the pod shows CreateContainerConfigError
kubectl get pods -n d8f3b6a1c2e4-crashloop
kubectl describe pod -n d8f3b6a1c2e4-crashloop -l app=config-app | grep -A5 Events
# Events reveal: configmap "app-settings" not found, then secret "app-credentials" not found

# Fix 1: the init container reads key db_host from ConfigMap app-settings
kubectl create configmap app-settings -n d8f3b6a1c2e4-crashloop \
  --from-literal=db_host=mysql.example.com

# Fix 2: the main container loads env from Secret app-credentials
kubectl create secret generic app-credentials -n d8f3b6a1c2e4-crashloop \
  --from-literal=DB_USER=admin --from-literal=DB_PASS=s3cret

# The kubelet retries automatically - no need to delete the pod
kubectl rollout status deployment/config-app -n d8f3b6a1c2e4-crashloop --timeout=120s
kubectl get pods -n d8f3b6a1c2e4-crashloop
