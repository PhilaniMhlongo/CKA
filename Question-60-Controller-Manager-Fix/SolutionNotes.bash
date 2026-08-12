# 1. Deployments -> ReplicaSets -> Pods is driven by the controller manager.
#    Confirm it is unhealthy:
kubectl get pods -n kube-system | grep controller-manager     # CrashLoopBackOff
kubectl logs -n kube-system kube-controller-manager-$(hostname) --tail=20
# error: "unable to load client config ... controller-manager-missing.conf"

# 2. Fix the static pod manifest
grep kubeconfig /etc/kubernetes/manifests/kube-controller-manager.yaml
sed -i 's|--kubeconfig=/etc/kubernetes/controller-manager-missing.conf|--kubeconfig=/etc/kubernetes/controller-manager.conf|' \
  /etc/kubernetes/manifests/kube-controller-manager.yaml
# (or restore from the backup in ./kcm-backup/)

# 3. The kubelet restarts the static pod automatically; wait, then verify
sleep 30
kubectl get pods -n kube-system | grep controller-manager     # Running
kubectl rollout status deployment/kcm-test -n d8f3b6a1c2e4-kcm-fix --timeout=120s
kubectl get rs,pods -n d8f3b6a1c2e4-kcm-fix
