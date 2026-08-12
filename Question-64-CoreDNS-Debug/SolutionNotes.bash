# Cause 1: CoreDNS has been scaled to zero
kubectl get deployment coredns -n kube-system        # READY 0/0
kubectl scale deployment coredns -n kube-system --replicas=2

# DNS still fails -> Cause 2: the Corefile zone was corrupted
kubectl get configmap coredns -n kube-system -o yaml | grep -n cluster
# "kubernetes cluster.broken in-addr.arpa ip6.arpa" -> must be cluster.local

# Fix it in place (kubectl edit works too)
kubectl get configmap coredns -n kube-system -o yaml \
  | sed 's/cluster\.broken/cluster.local/g' \
  | kubectl apply -f -

# CoreDNS only reads the Corefile at start -> restart it
kubectl rollout restart deployment coredns -n kube-system
kubectl rollout status deployment coredns -n kube-system --timeout=120s

# Verify
kubectl exec dns-client -n d8f3b6a1c2e4-dns-debug -- nslookup kubernetes.default.svc.cluster.local
