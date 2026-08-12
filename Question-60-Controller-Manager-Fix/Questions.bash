# Question: Broken Controller Manager (Troubleshooting - harder than exam)
# REQUIRES: control-plane node access (kubeadm cluster, e.g. Killercoda)

# Users report that new deployments in the cluster never create any pods.
# The deployment d8f3b6a1c2e4-kcm-fix/kcm-test shows 0/2 replicas and no
# ReplicaSet has been created for it. Existing pods keep running fine.

# Task
# 1. Work out which control-plane component is responsible for creating
#    ReplicaSets from Deployments, and confirm it is unhealthy
# 2. Find the root cause in its static pod manifest and fix it
# 3. Verify kcm-test reaches 2/2 available replicas

# Hints (only if stuck):
# - kubectl get pods -n kube-system
# - kubectl logs / crictl logs for the failing component
# - static pod manifests live in /etc/kubernetes/manifests/

# Documentation Reference
# Concepts -> Architecture -> kube-controller-manager
# https://kubernetes.io/docs/concepts/architecture/#kube-controller-manager
