# The kubelet's staticPodPath on kubeadm clusters is /etc/kubernetes/manifests
# (confirm with: grep staticPodPath /var/lib/kubelet/config.yaml)

cat <<'EOF' > /etc/kubernetes/manifests/static-web.yaml
apiVersion: v1
kind: Pod
metadata:
  name: static-web
  namespace: default
  labels:
    role: static-demo
spec:
  containers:
    - name: nginx
      image: nginx:1.25
EOF

# The kubelet picks it up within seconds and registers a MIRROR pod
sleep 10
kubectl get pods -n default -o wide | grep static-web    # static-web-<node-name>

# The mirror pod is owned by the Node, not by a controller
kubectl get pod -n default static-web-$(hostname) -o jsonpath='{.metadata.ownerReferences[0].kind}'   # Node

# Deleting the mirror pod does nothing lasting - kubelet recreates it.
# To remove it for real: rm /etc/kubernetes/manifests/static-web.yaml
