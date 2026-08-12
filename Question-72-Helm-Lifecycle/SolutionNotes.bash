# 1. Repo
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# 2. Install (revision 1)
helm install web-lifecycle bitnami/nginx \
  --namespace d8f3b6a1c2e4-helm-lab \
  --set replicaCount=1

# 3. Upgrade (revision 2)
helm upgrade web-lifecycle bitnami/nginx \
  --namespace d8f3b6a1c2e4-helm-lab \
  --set replicaCount=3
helm history web-lifecycle -n d8f3b6a1c2e4-helm-lab

# 4. Rollback to revision 1 (creates revision 3)
helm rollback web-lifecycle 1 -n d8f3b6a1c2e4-helm-lab

# 5. Verify
helm history web-lifecycle -n d8f3b6a1c2e4-helm-lab       # 3 revisions, last = Rollback to 1
helm status web-lifecycle -n d8f3b6a1c2e4-helm-lab | grep STATUS
kubectl get deployment -n d8f3b6a1c2e4-helm-lab           # back to 1 replica
