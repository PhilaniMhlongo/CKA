#!/bin/bash
set -e

echo "Creating namespace..."
kubectl create namespace d8f3b6a1c2e4-dev --dry-run=client -o yaml | kubectl apply -f -

if ! command -v openssl >/dev/null 2>&1; then
  echo "ERROR: openssl is required for this lab."
  exit 1
fi

echo "[OK] Lab setup complete."
echo "   - Namespace: d8f3b6a1c2e4-dev"
echo "You can now onboard the 'dev-user' via the CertificateSigningRequest API."
