#!/bin/bash
# Validation script for Question 48 - StorageClass + PVC (no-provisioner)
set -uo pipefail

PASS=0
FAIL=0
TOTAL=0

check() {
  local description="$1"
  shift
  TOTAL=$((TOTAL + 1))
  if "$@" >/dev/null 2>&1; then
    echo "  PASS: $description"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $description"
    FAIL=$((FAIL + 1))
  fi
}

echo "============================================"
echo " Validating Question 48: StorageClass + PVC (no-provisioner)"
echo "============================================"

check "StorageClass '7b43d4b5300b-fast-storage' uses kubernetes.io/no-provisioner" \
  bash -c 'kubectl get storageclass 7b43d4b5300b-fast-storage -o jsonpath="{.provisioner}" | grep -qx "kubernetes.io/no-provisioner"'

check "PVC 'data-pvc' exists in 7b43d4b5300b-storage" \
  kubectl get pvc data-pvc -n 7b43d4b5300b-storage

check "PVC uses the 7b43d4b5300b-fast-storage StorageClass" \
  bash -c 'kubectl get pvc data-pvc -n 7b43d4b5300b-storage -o jsonpath="{.spec.storageClassName}" | grep -qx "7b43d4b5300b-fast-storage"'

check "PVC requests 1Gi with ReadWriteOnce" \
  bash -c 'kubectl get pvc data-pvc -n 7b43d4b5300b-storage -o jsonpath="{.spec.resources.requests.storage}|{.spec.accessModes[0]}" | grep -qx "1Gi|ReadWriteOnce"'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
