#!/bin/bash
set -e

echo "Checking that helm is installed..."
if ! command -v helm >/dev/null 2>&1; then
  echo "ERROR: helm is not installed. Install it first:"
  echo "  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
  exit 1
fi
helm version --short

echo "[OK] Lab setup complete."
echo "You can now add the Bitnami repo and install the release."
