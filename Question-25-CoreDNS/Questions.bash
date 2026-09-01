# Question CoreDNS
# DOMAIN: Troubleshooting

# Context:
# Pods in the dns-lab namespace can resolve other Services inside the cluster,
# but every lookup of an external name times out. A Deployment named backend and
# a Service named backend already exist in the dns-lab namespace.

# Tasks:
# 1. Find and fix the CoreDNS misconfiguration so that Pods can resolve external
#    names again, using the node's own resolver configuration as the upstream.
#    Do not change anything other than what is broken.
# 2. Without breaking task 1, configure CoreDNS so that queries for
#    backend.dns-lab.example.com resolve to the same address as
#    backend.dns-lab.svc.cluster.local
# 3. Make sure the change is actually loaded by the running CoreDNS Pods

# Verify with:
#   kubectl -n dns-lab run dnstest --rm -it --image=busybox:stable --restart=Never \
#     -- nslookup backend.dns-lab.svc.cluster.local
#   kubectl -n dns-lab run dnstest --rm -it --image=busybox:stable --restart=Never \
#     -- nslookup backend.dns-lab.example.com
#   kubectl -n dns-lab run dnstest --rm -it --image=busybox:stable --restart=Never \
#     -- nslookup kubernetes.io

# Note: CoreDNS reads its Corefile from the 'coredns' ConfigMap in kube-system.
# The plugin that reloads it on change is not always enabled - check whether you
# need to restart the Deployment for your edit to take effect.

# Video Link - (none)

#Documentation Reference
# Tip: Navigate the documentation manually to build familiarity with its structure
# Tasks -> Administer a Cluster -> Using CoreDNS for Service Discovery
# https://kubernetes.io/docs/tasks/administer-cluster/coredns/
# Concepts -> Services... -> DNS for Services and Pods
# https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/
# CoreDNS rewrite plugin: https://coredns.io/plugins/rewrite/
