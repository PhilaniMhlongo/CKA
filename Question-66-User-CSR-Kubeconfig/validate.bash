#!/bin/bash
# Validation script for Question 66 - Onboard a User via CSR + Kubeconfig
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

WORKDIR="${WORKDIR:-$PWD/csr-work}"

echo "============================================"
echo " Validating Question 66: Onboard a User via CSR + Kubeconfig"
echo "============================================"

check "CSR 'dev-user' is Approved" \
  bash -c 'kubectl get csr dev-user -o jsonpath="{.status.conditions[?(@.type==\"Approved\")].status}" | grep -qx True'

check "CSR has an issued certificate" \
  bash -c 'kubectl get csr dev-user -o jsonpath="{.status.certificate}" | grep -q .'

check "CSR used the kube-apiserver-client signer" \
  bash -c 'kubectl get csr dev-user -o jsonpath="{.spec.signerName}" | grep -qx "kubernetes.io/kube-apiserver-client"'

check "RoleBinding 'dev-user-edit' binds ClusterRole edit to User dev-user" \
  bash -c '
    kubectl get rolebinding dev-user-edit -n d8f3b6a1c2e4-dev -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
ref = data[\"roleRef\"]
if ref[\"kind\"] == \"ClusterRole\" and ref[\"name\"] == \"edit\":
    for s in data.get(\"subjects\", []):
        if s[\"kind\"] == \"User\" and s[\"name\"] == \"dev-user\":
            sys.exit(0)
sys.exit(1)
"'

check "dev-user can create deployments in the namespace" \
  kubectl auth can-i create deployments --as=dev-user -n d8f3b6a1c2e4-dev

check "dev-user can NOT list namespaces cluster-wide" \
  bash -c '! kubectl auth can-i list namespaces --as=dev-user >/dev/null 2>&1'

check "Kubeconfig file exists with embedded client certificate" \
  bash -c 'test -f "'"$WORKDIR"'/dev-user.kubeconfig" && grep -q client-certificate-data "'"$WORKDIR"'/dev-user.kubeconfig"'

check "Kubeconfig actually authenticates (get pods succeeds)" \
  kubectl --kubeconfig "$WORKDIR/dev-user.kubeconfig" get pods -n d8f3b6a1c2e4-dev

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
