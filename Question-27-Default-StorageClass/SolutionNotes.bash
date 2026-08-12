# Create the StorageClass with the default-class annotation
cat <<'EOF' > fast-local-sc.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: eda9e0ec987a-fast-local
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
EOF
kubectl apply -f fast-local-sc.yaml

# Verify (should print rancher.io/local-path|WaitForFirstConsumer|true)
kubectl get sc eda9e0ec987a-fast-local \
  -o jsonpath='{.provisioner}|{.volumeBindingMode}|{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}'
