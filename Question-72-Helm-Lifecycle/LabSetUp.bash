#!/bin/bash
set -e

if ! command -v helm >/dev/null 2>&1; then
  echo "ERROR: helm is not installed. Install it first:"
  echo "  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
  exit 1
fi
helm version --short

echo "Creating namespace..."
kubectl create namespace d8f3b6a1c2e4-helm-lab --dry-run=client -o yaml | kubectl apply -f -

echo "[OK] Lab setup complete."
echo "   - Namespace: d8f3b6a1c2e4-helm-lab"
echo "Run the full install -> upgrade -> rollback lifecycle."
