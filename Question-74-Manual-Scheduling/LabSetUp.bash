#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKDIR="${WORKDIR:-$SCRIPT_DIR/manual-sched-work}"

echo "Creating namespace..."
kubectl create namespace d8f3b6a1c2e4-manual-sched --dry-run=client -o yaml | kubectl apply -f -

echo "Preparing working directory $WORKDIR ..."
mkdir -p "$WORKDIR"

echo "Picking a target node for this lab..."
# Prefer a schedulable worker; fall back to any node on single-node clusters.
TARGET_NODE=$(kubectl get nodes -o json | python3 -c '
import json, sys
data = json.load(sys.stdin)
def usable(n):
    return not n["spec"].get("unschedulable")
workers = [n["metadata"]["name"] for n in data["items"]
           if usable(n) and "node-role.kubernetes.io/control-plane" not in n["metadata"].get("labels", {})]
anyn = [n["metadata"]["name"] for n in data["items"] if usable(n)]
print((workers or anyn or [""])[0])
')

if [[ -z "$TARGET_NODE" ]]; then
  echo "ERROR: could not find a schedulable node." >&2
  exit 1
fi

echo "$TARGET_NODE" > "$WORKDIR/target-node.txt"
echo "   Target node for this lab: $TARGET_NODE"

echo "Creating a pod that no scheduler will ever pick up..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: orphan-pod
  namespace: d8f3b6a1c2e4-manual-sched
  labels:
    app: orphan-pod
spec:
  schedulerName: cka-no-scheduler
  containers:
    - name: nginx
      image: nginx:1.25
EOF

# Record the pod UID so validation can prove it was bound, not recreated.
sleep 2
kubectl get pod orphan-pod -n d8f3b6a1c2e4-manual-sched -o jsonpath='{.metadata.uid}' \
  > "$WORKDIR/orphan-pod.uid"

echo "[OK] Lab setup complete."
echo "   - Namespace:   d8f3b6a1c2e4-manual-sched"
echo "   - Working dir: $WORKDIR (target-node.txt names the node to use)"
echo "   - orphan-pod is Pending and will stay Pending until you bind it."
