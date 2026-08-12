# 1. Find where the pods run and watch the drain fail
kubectl get pods -n d8f3b6a1c2e4-pdb-drain -o wide
kubectl drain <NODE_NAME> --ignore-daemonsets --delete-emptydir-data --timeout=30s
# "Cannot evict pod as it would violate the pod's disruption budget"

# 2. Loosen the PDB (do NOT delete it)
kubectl patch pdb pdb-app-guard -n d8f3b6a1c2e4-pdb-drain \
  --type='merge' -p '{"spec":{"maxUnavailable":1}}'

# 3. Drain again - evictions now proceed one at a time
kubectl drain <NODE_NAME> --ignore-daemonsets --delete-emptydir-data

# 4. Verify: node cordoned, pods rescheduled elsewhere
kubectl get nodes                                   # <NODE_NAME> SchedulingDisabled
kubectl get pods -n d8f3b6a1c2e4-pdb-drain -o wide  # no pod on <NODE_NAME>

# (After real maintenance you would: kubectl uncordon <NODE_NAME> -
#  the cleanup script does this for you.)
