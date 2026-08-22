#!/usr/bin/env bash
# Wipe everything Set 3 creates so you can retake it cleanly.
echo ">> uninstalling helm release..."
helm uninstall web-release -n helm-test >/dev/null 2>&1
echo ">> deleting Set 3 namespaces..."
kubectl delete ns manual-storage stateful limits consumer priority dns-config kustomize helm-test gateway \
  --ignore-not-found --wait=false
echo ">> deleting cluster-scoped objects..."
kubectl delete pv manual-pv --ignore-not-found
kubectl delete sc fast-local cold --ignore-not-found
kubectl delete priorityclass high-priority low-priority --ignore-not-found
rm -rf /tmp/exam/kustomize
rm -f "$(dirname "$0")/.started"
echo ">> Gateway API CRDs left installed (harmless). Remove manually if you want a cold start."
echo ">> done. Re-run ./start.sh 3 when ready."
