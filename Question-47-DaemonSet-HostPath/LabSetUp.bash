#!/bin/bash
set -e

echo "Creating namespace..."
kubectl create namespace 7b43d4b5300b-logging --dry-run=client -o yaml | kubectl apply -f -

echo "[OK] Lab setup complete."
echo "   - Namespace: 7b43d4b5300b-logging"
echo "You can now create the log-collector DaemonSet."
