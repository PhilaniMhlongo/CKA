# Step 0 - confirm the symptom and narrow it down. In-cluster names working while
# external names fail points at the forward plugin, not at the kubernetes plugin,
# not at kube-dns Service endpoints.
kubectl -n dns-lab run dnstest --rm -it --image=busybox:stable --restart=Never \
  -- nslookup backend.dns-lab.svc.cluster.local     # works
kubectl -n dns-lab run dnstest --rm -it --image=busybox:stable --restart=Never \
  -- nslookup kubernetes.io                          # times out

# Check that CoreDNS itself is healthy before blaming config
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=50
kubectl get svc kube-dns -n kube-system
kubectl get endpoints kube-dns -n kube-system        # must have addresses

# Step 1 - read the Corefile
kubectl get configmap coredns -n kube-system -o yaml
# The forward line points at 240.0.0.1 (a reserved, unroutable address) instead
# of /etc/resolv.conf, so every upstream query blackholes.

kubectl edit configmap coredns -n kube-system
# change:   forward . 240.0.0.1
# back to:  forward . /etc/resolv.conf

# Step 2 - add the rewrite. The rewrite plugin rewrites the incoming query name
# before the kubernetes plugin sees it, so the answer comes back from the normal
# in-cluster record. Place it before the kubernetes plugin in the Corefile.
#
# Inside the ".:53 { ... }" block add:
#
#   rewrite name backend.dns-lab.example.com backend.dns-lab.svc.cluster.local
#
# A resulting Corefile looks roughly like:
#
#   .:53 {
#       errors
#       health {
#          lameduck 5s
#       }
#       ready
#       rewrite name backend.dns-lab.example.com backend.dns-lab.svc.cluster.local
#       kubernetes cluster.local in-addr.arpa ip6.arpa {
#          pods insecure
#          fallthrough in-addr.arpa ip6.arpa
#          ttl 30
#       }
#       prometheus :9153
#       forward . /etc/resolv.conf
#       cache 30
#       loop
#       reload
#       loadbalance
#   }

# Step 3 - make the running pods pick it up.
# The "reload" plugin polls the Corefile roughly every 30s, but it is not always
# present, and it will not reload a file that fails to parse. Restarting is the
# deterministic option:
kubectl rollout restart deployment coredns -n kube-system
kubectl rollout status deployment coredns -n kube-system

# Step 4 - verify all three lookups
kubectl -n dns-lab run dnstest --rm -it --image=busybox:stable --restart=Never \
  -- nslookup backend.dns-lab.svc.cluster.local
kubectl -n dns-lab run dnstest --rm -it --image=busybox:stable --restart=Never \
  -- nslookup backend.dns-lab.example.com
kubectl -n dns-lab run dnstest --rm -it --image=busybox:stable --restart=Never \
  -- nslookup kubernetes.io

# If CoreDNS crashloops after an edit, the Corefile failed to parse - check with:
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=30
