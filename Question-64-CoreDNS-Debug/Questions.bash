# Question: Cluster DNS Outage (Troubleshooting)
# WARNING: this lab intentionally breaks cluster-wide DNS until you fix it.

# Every pod in the cluster suddenly fails to resolve service names:
#   kubectl exec dns-client -n d8f3b6a1c2e4-dns-debug -- nslookup kubernetes.default.svc.cluster.local
# times out. There are TWO separate causes, both in kube-system.

# Task
# 1. Check the CoreDNS deployment - why are there no DNS pods at all?
#    Restore them.
# 2. DNS still fails afterwards. Inspect the CoreDNS ConfigMap (Corefile)
#    closely - the cluster zone is wrong. Fix it and restart CoreDNS.
# 3. End state:
#    - CoreDNS has ready replicas
#    - the nslookup above succeeds from dns-client

# Documentation Reference
# Tasks -> Administer a Cluster -> Debugging DNS Resolution
# https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/
