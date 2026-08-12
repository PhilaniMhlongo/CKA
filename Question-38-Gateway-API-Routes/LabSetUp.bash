#!/bin/bash
set -e

echo "Installing Gateway API CRDs..."
kubectl apply -k "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.1.0" >/dev/null

echo "Creating namespace..."
kubectl create namespace eda9e0ec987a-gateway --dry-run=client -o yaml | kubectl apply -f -

echo "Creating GatewayClass 'example'..."
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: example
spec:
  controllerName: example.com/gateway-controller
EOF

echo "[OK] Lab setup complete."
echo "   - Namespace: eda9e0ec987a-gateway"
echo "   - GatewayClass: example"
echo "You can now create the deployments, services, Gateway and HTTPRoute."
