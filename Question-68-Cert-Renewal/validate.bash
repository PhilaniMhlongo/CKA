#!/bin/bash
# Validation script for Question 68 - kubeadm Certificate Renewal
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
echo " Validating Question 68: kubeadm Certificate Renewal"
echo "============================================"

check "Before-snapshot exists and mentions the apiserver cert" \
  bash -c 'test -s /tmp/exam/cert-expiration-before.txt && grep -q apiserver /tmp/exam/cert-expiration-before.txt'

check "After-snapshot exists and is non-empty" \
  test -s /tmp/exam/cert-expiration-after.txt

check "apiserver.crt is valid for more than 300 days (was renewed)" \
  openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -checkend 25920000

check "API server still answers (cluster healthy after renewal)" \
  kubectl get --raw /readyz

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
