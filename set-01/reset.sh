#!/usr/bin/env bash
# Wipe everything Set 1 creates so you can retake it cleanly.
echo ">> deleting Set 1 namespaces..."
kubectl delete ns app-team1 config storage-task web networking rbac scaling scheduling logging troubleshoot \
  --ignore-not-found --wait=false
echo ">> removing node label disk=ssd..."
for n in $(kubectl get nodes -o name); do kubectl label "$n" disk- >/dev/null 2>&1; done
rm -f "$(dirname "$0")/.started"
echo ">> done. Re-run ./start.sh 1 when ready."
