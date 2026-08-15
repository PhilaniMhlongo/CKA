# Find the endpoint and the cert paths from the etcd static pod manifest:
grep -E "listen-client-urls|trusted-ca-file|cert-file|key-file|data-dir" \
  /etc/kubernetes/manifests/etcd.yaml

# 1. Take the snapshot (API v3 is the default in recent etcdctl, set it anyway)
export ETCDCTL_API=3
etcdctl snapshot save /opt/etcd-backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# 2. Verify it and keep the output
etcdctl snapshot status /opt/etcd-backup.db --write-out=table \
  | tee /opt/etcd-snapshot-status.txt

# 3. Simulate the post-backup incident
kubectl delete configmap pre-backup-marker -n d8f3b6a1c2e4-etcd-restore
kubectl create configmap post-backup-marker -n d8f3b6a1c2e4-etcd-restore \
  --from-literal=state=created-after-the-backup

# 4. Restore into a NEW data directory (never restore over the live one)
etcdctl snapshot restore /opt/etcd-backup.db \
  --data-dir=/var/lib/etcd-restore

# Point the etcd static pod at the restored directory. Only the hostPath on
# the host side changes - the mountPath inside the container stays the same.
#   volumes:
#     - name: etcd-data
#       hostPath:
#         path: /var/lib/etcd-restore     <-- was /var/lib/etcd
vim /etc/kubernetes/manifests/etcd.yaml

# The kubelet restarts etcd when the manifest changes. If it is slow, force it:
#   mv /etc/kubernetes/manifests/etcd.yaml /tmp/ && sleep 10 && mv /tmp/etcd.yaml /etc/kubernetes/manifests/
# Watch it come back (the API server is briefly unavailable - this is expected):
crictl ps | grep etcd

# 5. Verify the rollback actually happened
kubectl get nodes
kubectl get configmap -n d8f3b6a1c2e4-etcd-restore
#   pre-backup-marker   -> present again
#   post-backup-marker  -> gone
