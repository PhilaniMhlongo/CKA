NODE=$(cat ./manual-sched-work/target-node.txt)

# 1. spec.nodeName bypasses the scheduler entirely - the kubelet on that node
#    picks the pod up directly.
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: pinned-pod
  namespace: d8f3b6a1c2e4-manual-sched
spec:
  nodeName: $NODE
  containers:
    - name: nginx
      image: nginx:1.25
EOF

# 2. orphan-pod already exists, so nodeName cannot be added (it is immutable).
#    Post a Binding instead - this is exactly what kube-scheduler itself does.
kubectl create -f - <<EOF
apiVersion: v1
kind: Binding
metadata:
  name: orphan-pod
  namespace: d8f3b6a1c2e4-manual-sched
target:
  apiVersion: v1
  kind: Node
  name: $NODE
EOF

# Equivalent, straight against the binding subresource:
#   kubectl proxy --port=8001 &
#   curl -sS http://127.0.0.1:8001/api/v1/namespaces/d8f3b6a1c2e4-manual-sched/pods/orphan-pod/binding \
#     -H "Content-Type: application/json" \
#     -d "{\"apiVersion\":\"v1\",\"kind\":\"Binding\",\"metadata\":{\"name\":\"orphan-pod\"},\"target\":{\"apiVersion\":\"v1\",\"kind\":\"Node\",\"name\":\"$NODE\"}}"

# Verify both landed on the target node and orphan-pod kept its identity
kubectl get pods -n d8f3b6a1c2e4-manual-sched -o wide
kubectl get pod orphan-pod -n d8f3b6a1c2e4-manual-sched \
  -o jsonpath='{.spec.schedulerName}{"\n"}{.metadata.uid}{"\n"}'
