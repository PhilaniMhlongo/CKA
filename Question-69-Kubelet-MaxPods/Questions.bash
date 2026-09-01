# Question: Kubelet Configuration - maxPods (Cluster Architecture)
# DOMAIN: ClusterArchitecture
# REQUIRES: node access with root (kubeadm cluster, e.g. Killercoda)

# The platform team wants to cap this node at 40 pods.

# Task
# 1. On this node, edit the kubelet configuration file
#    (/var/lib/kubelet/config.yaml) and set maxPods: 40
# 2. Restart the kubelet and confirm it comes back healthy
#    (systemctl restart kubelet / systemctl status kubelet)
# 3. Verify the node now advertises a pod capacity of 40:
#    kubectl get node <node> -o jsonpath='{.status.capacity.pods}'

# Documentation Reference
# Tasks -> Administer a Cluster -> Reconfigure a Node's Kubelet
# https://kubernetes.io/docs/tasks/administer-cluster/kubelet-config-file/
