#!/usr/bin/env bash
# Wipe everything Set 2 creates or seeds.
set -u
echo ">> deleting Set 2 namespaces..."
kubectl delete ns svcn-cka05 svcn-cka04 trb-cka24 web-cka06-trb cyan-ns-cka28-trb dev-wl07 \
  --ignore-not-found --wait=false >/dev/null 2>&1
echo ">> deleting default-namespace objects..."
kubectl delete pod cyan-white-cka28-trb1 cyan-black-cka28-trb --ignore-not-found --force --grace-period=0 >/dev/null 2>&1
kubectl delete secret db-user-pass-cka17-arch --ignore-not-found >/dev/null 2>&1
kubectl delete sa deploy-cka20-arch --ignore-not-found >/dev/null 2>&1
kubectl delete pvc apple-pvc-cka04-str --ignore-not-found >/dev/null 2>&1
echo ">> deleting cluster-scoped objects..."
kubectl delete clusterrole deploy-role-cka20-arch --ignore-not-found >/dev/null 2>&1
kubectl delete clusterrolebinding deploy-role-binding-cka20-arch --ignore-not-found >/dev/null 2>&1
kubectl delete pv apple-pv-cka04-str --ignore-not-found >/dev/null 2>&1
kubectl delete sc banana-sc-cka08-str --ignore-not-found >/dev/null 2>&1
echo ">> removing generated files..."
rm -f /opt/db-user-pass /root/pod_ips_cka05_svcn /root/rolling-back-record.txt
rm -f "$(dirname "$0")/.started"
echo ">> done. Re-run ./start.sh 2 when ready."
