#!/bin/bash
# Validation script for Question 33 - Headless Service + StatefulSet
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
echo " Validating Question 33: Headless Service + StatefulSet"
echo "============================================"

check "Service 'web-svc' is headless (clusterIP None)" \
  bash -c 'kubectl get svc web-svc -n eda9e0ec987a-stateful -o jsonpath="{.spec.clusterIP}" | grep -qx None'

check "Service selects app=web" \
  bash -c 'kubectl get svc web-svc -n eda9e0ec987a-stateful -o jsonpath="{.spec.selector.app}" | grep -qx web'

check "StatefulSet 'web' has 3 replicas and serviceName web-svc" \
  bash -c 'kubectl get statefulset web -n eda9e0ec987a-stateful -o jsonpath="{.spec.replicas}|{.spec.serviceName}" | grep -qx "3|web-svc"'

check "volumeClaimTemplate 'www' requests 1Gi from StorageClass cold" \
  bash -c '
    kubectl get statefulset web -n eda9e0ec987a-stateful -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for vct in data[\"spec\"].get(\"volumeClaimTemplates\", []):
    if vct[\"metadata\"][\"name\"] != \"www\":
        continue
    spec = vct[\"spec\"]
    if spec.get(\"storageClassName\") == \"cold\" and spec[\"resources\"][\"requests\"][\"storage\"] == \"1Gi\":
        sys.exit(0)
sys.exit(1)
"'

check "Volume 'www' is mounted at /usr/share/nginx/html" \
  bash -c '
    kubectl get statefulset web -n eda9e0ec987a-stateful -o json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for c in data[\"spec\"][\"template\"][\"spec\"][\"containers\"]:
    for m in c.get(\"volumeMounts\", []):
        if m[\"name\"] == \"www\" and m[\"mountPath\"] == \"/usr/share/nginx/html\":
            sys.exit(0)
sys.exit(1)
"'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "All checks passed!" || echo "Some checks failed."

exit $FAIL
