# Add the repo and install the chart
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install web-release bitnami/nginx \
  --namespace eda9e0ec987a-helm-test --create-namespace \
  --set service.type=NodePort \
  --set replicaCount=2

# Verify
helm list -n eda9e0ec987a-helm-test
kubectl get pods,svc -n eda9e0ec987a-helm-test
