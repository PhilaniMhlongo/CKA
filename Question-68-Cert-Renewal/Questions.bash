# Question: kubeadm Certificate Inspection & Renewal (Cluster Architecture)
# REQUIRES: control-plane node access (kubeadm cluster, e.g. Killercoda)

# Task
# 1. Save the current certificate expiration overview to
#    /tmp/exam/cert-expiration-before.txt (kubeadm certs check-expiration)
# 2. Renew ONLY the apiserver serving certificate (not all certs)
# 3. Save the new overview to /tmp/exam/cert-expiration-after.txt
# 4. Independently confirm the renewal with openssl against
#    /etc/kubernetes/pki/apiserver.crt (check the notAfter date moved)

# Documentation Reference
# Tasks -> Administer a Cluster -> Certificate Management with kubeadm
# https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/
