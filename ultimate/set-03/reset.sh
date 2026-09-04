#!/usr/bin/env bash
# Wipe everything Set 3 creates or seeds.
set -u
echo ">> deleting Set 3 namespaces..."
kubectl delete ns msg-cka07 hr-cka08 wl06-cka trb-cka12 db-cka05-trb blue-cka09-trb \
  --ignore-not-found --wait=false >/dev/null 2>&1
echo ">> deleting default-namespace objects..."
kubectl delete deploy ocean-tv-wl09 --ignore-not-found >/dev/null 2>&1
kubectl delete pod peach-pod-cka05-str app-wl03 --ignore-not-found --force --grace-period=0 >/dev/null 2>&1
kubectl delete pvc peach-pvc-cka05-str --ignore-not-found >/dev/null 2>&1
kubectl delete pv peach-pv-cka05-str --ignore-not-found >/dev/null 2>&1
echo ">> removing generated files..."
rm -f /opt/revision-count.txt /opt/cluster1_backup.db /opt/etcd-snapshot-status.txt
rm -f /root/peach-pod-cka05-str.yaml /root/app-wl03.yaml /root/red-probe-cka12-trb.yaml
rm -f "$(dirname "$0")/.started"
echo ">> done. Re-run ./start.sh 3 when ready."
