#!/usr/bin/env bash
# Wipe everything Set 1 creates or seeds, so you can retake it cleanly.
set -u
echo ">> deleting Set 1 namespaces..."
kubectl delete ns secure-sys-cka12-arch grape-cka06-str app-space app-cka07-trb \
  yello-cka20-trb web-cka17-trb --ignore-not-found --wait=false >/dev/null 2>&1
echo ">> deleting default-namespace objects..."
kubectl delete pod elastic-app-cka02-arch looper-cka16-arch nginx-resolver-cka06-svcn \
  --ignore-not-found --force --grace-period=0 >/dev/null 2>&1
kubectl delete svc nginx-resolver-service-cka06-svcn --ignore-not-found >/dev/null 2>&1
kubectl delete sa red-sa-cka23-arch --ignore-not-found >/dev/null 2>&1
echo ">> deleting cluster-scoped objects..."
kubectl delete clusterrole red-role-cka23-arch --ignore-not-found >/dev/null 2>&1
kubectl delete clusterrolebinding red-role-binding-cka23-arch --ignore-not-found >/dev/null 2>&1
kubectl delete pv web-pv-cka17-trb --ignore-not-found >/dev/null 2>&1
echo ">> removing the taint this set adds..."
for n in $(kubectl get nodes -o name 2>/dev/null); do
  kubectl taint "$n" app-type- >/dev/null 2>&1
done
echo ">> removing generated files..."
rm -rf /root/CKA /root/app-cka07-trb.yaml /opt/red-sa-cka23-arch
rm -f "$(dirname "$0")/.started"
echo ">> done. Re-run ./start.sh 1 when ready."
