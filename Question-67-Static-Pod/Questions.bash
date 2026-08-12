# Question: Static Pod (Cluster Architecture - harder than exam)
# REQUIRES: control-plane node access (kubeadm cluster, e.g. Killercoda)

# Task
# 1. On the control-plane node, create a STATIC pod named static-web:
#    - image nginx:1.25
#    - label role=static-demo
#    - namespace default
#    Place the manifest in the kubelet's static pod path
#    (/etc/kubernetes/manifests/static-web.yaml)
# 2. Verify the kubelet creates the mirror pod - its name will be
#    static-web-<node-name> and it is owned by the Node object
# 3. Bonus understanding: try kubectl delete on the mirror pod and watch
#    it come back - only removing the manifest file truly deletes it

# Documentation Reference
# Tasks -> Configure Pods and Containers -> Create Static Pods
# https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/
