#!/bin/bash
# Validation script for Question 23 - RBAC
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

echo "==========================================="
echo " Validating Question 23: RBAC"
echo "==========================================="

SA="system:serviceaccount:finance:report-runner"

# Effective-permission helpers. These are the real test: they exercise the
# authorizer the same way the API server will, so they pass regardless of how
# the learner structured the roles.
can() {
  local verb="$1" resource="$2" ns="$3"
  [[ "$(kubectl auth can-i "$verb" "$resource" -n "$ns" --as="$SA" 2>/dev/null)" == "yes" ]]
}

cannot() {
  ! can "$@"
}

# 1. The objects the task names must exist with the names given
check "Role 'pod-reader' exists in namespace 'finance'" \
  kubectl get role pod-reader -n finance

check "RoleBinding 'report-runner-read' exists in namespace 'finance'" \
  kubectl get rolebinding report-runner-read -n finance

check "RoleBinding 'report-runner-read' targets Role 'pod-reader'" \
  bash -c '
    ROLE=$(kubectl get rolebinding report-runner-read -n finance -o jsonpath="{.roleRef.name}" 2>/dev/null)
    KIND=$(kubectl get rolebinding report-runner-read -n finance -o jsonpath="{.roleRef.kind}" 2>/dev/null)
    [[ "$ROLE" == "pod-reader" && "$KIND" == "Role" ]]
  '

check "RoleBinding 'report-runner-read' subject is the report-runner ServiceAccount" \
  bash -c '
    kubectl get rolebinding report-runner-read -n finance -o json 2>/dev/null |
      python3 -c "
import json, sys
rb = json.load(sys.stdin)
subjects = rb.get(\"subjects\") or []
ok = any(
    s.get(\"kind\") == \"ServiceAccount\"
    and s.get(\"name\") == \"report-runner\"
    and s.get(\"namespace\", \"finance\") == \"finance\"
    for s in subjects
)
sys.exit(0 if ok else 1)
"
  '

# 2. Granted permissions in finance
check "Can list pods in finance" can list pods finance
check "Can get pods in finance" can get pods finance
check "Can watch pods in finance" can watch pods finance
check "Can get configmaps in finance" can get configmaps finance
check "Can list configmaps in finance" can list configmaps finance

# 3. Granted permission in hr - pods only
check "Can list pods in hr" can list pods hr

# 4. Denied permissions. These are what separate a correct least-privilege
#    answer from an over-broad one (e.g. binding a ClusterRole cluster-wide).
check "Cannot get configmaps in hr" cannot get configmaps hr
check "Cannot list configmaps in hr" cannot list configmaps hr
check "Cannot delete pods in finance" cannot delete pods finance
check "Cannot delete pods in hr" cannot delete pods hr
check "Cannot create pods in finance" cannot create pods finance
check "Cannot list pods in the default namespace" cannot list pods default
check "Cannot list pods in kube-system" cannot list pods kube-system
check "Cannot list secrets in finance" cannot list secrets finance

# 5. No cluster-wide grant was used to solve task 3
check "No ClusterRoleBinding grants report-runner cluster-wide access" \
  bash -c '
    kubectl get clusterrolebindings -o json 2>/dev/null |
      python3 -c "
import json, sys
data = json.load(sys.stdin)
for crb in data.get(\"items\", []):
    for s in crb.get(\"subjects\") or []:
        if s.get(\"kind\") == \"ServiceAccount\" and s.get(\"name\") == \"report-runner\":
            name = crb.get(\"metadata\", {}).get(\"name\", \"?\")
            print(\"ClusterRoleBinding \" + name + \" binds report-runner\", file=sys.stderr)
            sys.exit(1)
sys.exit(0)
"
  '

echo ""
echo "==========================================="
echo " Summary"
echo "==========================================="
echo "  Passed: $PASS/$TOTAL"
echo "  Failed: $FAIL/$TOTAL"
echo "==========================================="

[[ $FAIL -eq 0 ]] && echo "  Result: SUCCESS" || echo "  Result: FAILURE"
exit $FAIL
