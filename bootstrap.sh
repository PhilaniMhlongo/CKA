#!/usr/bin/env bash
# Optional cluster prep so storage- and HPA-backed questions behave realistically.
# Safe to run more than once.
set -u
echo ">> installing local-path provisioner (rancher.io/local-path)..."
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.31/deploy/local-path-storage.yaml

echo ">> creating StorageClass 'standard' backed by the same provisioner..."
cat <<'YAML' | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
YAML

echo ">> installing metrics-server (kubelet TLS insecure, playground only)..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl -n kube-system patch deployment metrics-server --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]' 2>/dev/null

echo
echo ">> waiting for provisioner to be ready..."
kubectl -n local-path-storage rollout status deploy/local-path-provisioner --timeout=120s 2>/dev/null
echo ">> done. StorageClasses now available:"
kubectl get sc
