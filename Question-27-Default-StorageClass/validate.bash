#!/bin/bash
# Validation script for Question 27 - Default StorageClass
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
echo " Validating Question 27: Default StorageClass"
echo "============================================"

check "StorageClass 'eda9e0ec987a-fast-local' exists" \
  kubectl get storageclass eda9e0ec987a-fast-local

check "Provisioner is rancher.io/local-path" \
  bash -c 'kubectl get storageclass eda9e0ec987a-fast-local -o jsonpath="{.provisioner}" | grep -qx "rancher.io/local-path"'

check "volumeBindingMode is WaitForFirstConsumer" \
  bash -c 'kubectl get storageclass eda9e0ec987a-fast-local -o jsonpath="{.volumeBindingMode}" | grep -qx WaitForFirstConsumer'

check "Annotated as the default StorageClass" \
  bash -c 'kubectl get storageclass eda9e0ec987a-fast-local -o jsonpath="{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}" | grep -qx true'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
