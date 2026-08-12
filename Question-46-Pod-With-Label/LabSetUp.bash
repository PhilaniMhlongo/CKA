#!/bin/bash
set -e

echo "Creating namespace..."
kubectl create namespace 7b43d4b5300b-app-team1 --dry-run=client -o yaml | kubectl apply -f -

echo "[OK] Lab setup complete."
echo "   - Namespace: 7b43d4b5300b-app-team1"
echo "You can now create the labelled pod."
