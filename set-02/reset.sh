#!/usr/bin/env bash
# Wipe everything Set 2 creates so you can retake it cleanly.
echo ">> deleting Set 2 namespaces..."
kubectl delete ns monitoring probes storage scheduling security cluster-admin dns-debug network upgrade \
  --ignore-not-found --wait=false
echo ">> deleting StorageClass fast-storage..."
kubectl delete sc fast-storage --ignore-not-found
echo ">> removing taint special-workload from all nodes..."
for n in $(kubectl get nodes -o name); do kubectl taint "$n" special-workload- >/dev/null 2>&1; done
rm -rf /tmp/exam
rm -f "$(dirname "$0")/.started"
echo ">> done. Re-run ./start.sh 2 when ready."
