# Question: etcd Snapshot Backup and Restore (Cluster Architecture)
# DOMAIN: ClusterArchitecture
# DISRUPTIVE: restores etcd - rolls cluster state back to the snapshot. ATTEMPT LAST
# REQUIRES: control-plane node access (kubeadm cluster, e.g. Killercoda)

# The cluster stores its state in a stacked etcd running as a static pod on
# the controlplane node. In namespace d8f3b6a1c2e4-etcd-restore there is a
# ConfigMap pre-backup-marker that represents important cluster state.

# Task
# 1. Take a snapshot of the running etcd and save it to /opt/etcd-backup.db
#    (you must locate the correct endpoint and the CA / cert / key files
#    yourself - the etcd static pod manifest tells you where they are)
# 2. Verify the snapshot is valid and write the status output to
#    /opt/etcd-snapshot-status.txt
# 3. Now simulate the incident that happens AFTER the backup was taken:
#      - delete ConfigMap pre-backup-marker
#      - create ConfigMap post-backup-marker in the same namespace
# 4. Restore the snapshot into the data directory /var/lib/etcd-restore and
#    reconfigure the etcd static pod so the cluster actually serves the
#    restored data
# 5. End state:
#      - ConfigMap pre-backup-marker exists again
#      - ConfigMap post-backup-marker is GONE (it was never in the snapshot)
#      - kubectl get nodes succeeds and every node is Ready

# Documentation Reference
# Tasks -> Administer a Cluster -> Operating etcd clusters for Kubernetes
# https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/
# Tasks -> Administer a Cluster -> Backing up an etcd cluster
# https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/#backing-up-an-etcd-cluster
