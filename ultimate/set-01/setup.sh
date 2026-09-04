#!/usr/bin/env bash
# Seeds the state Set 1 expects, including the deliberately broken resources.
# Safe to re-run.
set -u
say() { printf "   %s\n" "$1"; }
apply() { kubectl apply -f - >/dev/null 2>&1; }
ns() { kubectl create namespace "$1" --dry-run=client -o yaml | kubectl apply -f - >/dev/null 2>&1; }

# ---------------------------------------------------------------- Q3 sidecar
cat <<'YAML' | apply
apiVersion: v1
kind: Pod
metadata:
  name: elastic-app-cka02-arch
  namespace: default
  labels: { app: elastic-app-cka02-arch }
spec:
  containers:
  - name: elastic-app
    image: busybox:1.36
    command: ["sh","-c","mkdir -p /var/log; while true; do echo \"$(date) app log line\" >> /var/log/elastic-app.log; sleep 5; done"]
    volumeMounts:
    - { name: log-volume, mountPath: /var/log }
  volumes:
  - { name: log-volume, emptyDir: {} }
YAML
say "seeded: pod elastic-app-cka02-arch (Q3)"

# ---------------------------------------------------------------- Q6 deployment to expose
ns app-space
cat <<'YAML' | apply
apiVersion: apps/v1
kind: Deployment
metadata: { name: webapp-wear-cka09-svcn, namespace: app-space }
spec:
  replicas: 2
  selector: { matchLabels: { app: webapp-wear-cka09-svcn } }
  template:
    metadata: { labels: { app: webapp-wear-cka09-svcn } }
    spec:
      containers:
      - name: web
        image: nginx:1.25
        ports: [ { containerPort: 80 } ]
YAML
say "seeded: deployment webapp-wear-cka09-svcn in app-space (Q6)"

# ---------------------------------------------------------------- Q7 RBAC to inspect
kubectl create serviceaccount red-sa-cka23-arch --dry-run=client -o yaml | apply
cat <<'YAML' | apply
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata: { name: red-role-cka23-arch }
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get","list","watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata: { name: red-role-binding-cka23-arch }
subjects:
- kind: ServiceAccount
  name: red-sa-cka23-arch
  namespace: default
roleRef:
  kind: ClusterRole
  name: red-role-cka23-arch
  apiGroup: rbac.authorization.k8s.io
YAML
say "seeded: red-sa-cka23-arch + cluster role/binding (Q7)"

# ---------------------------------------------------------------- Q8 broken template
mkdir -p /root
cat <<'YAML' > /root/app-cka07-trb.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-cka07-trb
  namespace: app-cka07-trb
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-cka07-trb
  template:
    metadata:
      labels:
        app: app-cka07-trb
    spec:
      containers:
      - name: app
        image: nginx:1.25
YAML
kubectl delete namespace app-cka07-trb --ignore-not-found >/dev/null 2>&1
say "seeded: /root/app-cka07-trb.yaml, namespace deliberately absent (Q8)"

# ---------------------------------------------------------------- Q9 taint vs toleration
ns yello-cka20-trb
NODE="$(kubectl get nodes -o jsonpath='{.items[?(@.spec.taints)].metadata.name}' 2>/dev/null | awk '{print $1}')"
TARGET="$(kubectl get nodes --no-headers -o custom-columns=N:.metadata.name | grep -v controlplane | head -1)"
[ -z "$TARGET" ] && TARGET="$(kubectl get nodes --no-headers -o custom-columns=N:.metadata.name | head -1)"
kubectl taint node "$TARGET" app-type=yello:NoSchedule --overwrite >/dev/null 2>&1
kubectl delete pod yello-cka20-trb -n yello-cka20-trb --ignore-not-found --force --grace-period=0 >/dev/null 2>&1
cat <<YAML | apply
apiVersion: v1
kind: Pod
metadata:
  name: yello-cka20-trb
  namespace: yello-cka20-trb
spec:
  nodeSelector:
    kubernetes.io/hostname: $TARGET
  tolerations:
  - key: "app-type"
    operator: "Equal"
    value: "blue"          # wrong value on purpose
    effect: "NoSchedule"
  containers:
  - name: nginx
    image: nginx:1.25
YAML
say "seeded: node $TARGET tainted app-type=yello:NoSchedule, pod tolerates the wrong value (Q9)"

# ---------------------------------------------------------------- Q10 two faults
ns web-cka17-trb
cat <<'YAML' | apply
apiVersion: v1
kind: PersistentVolume
metadata: { name: web-pv-cka17-trb }
spec:
  capacity: { storage: 100Mi }
  accessModes: ["ReadWriteOnce"]
  persistentVolumeReclaimPolicy: Retain
  storageClassName: web-cka17-trb
  hostPath: { path: /tmp/web-cka17-trb }
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata: { name: web-pvc-cka17-trb, namespace: web-cka17-trb }
spec:
  storageClassName: web-cka17-trb
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 150Mi          # larger than the PV on purpose
---
apiVersion: apps/v1
kind: Deployment
metadata: { name: web-dp-cka17-trb, namespace: web-cka17-trb }
spec:
  replicas: 1
  selector: { matchLabels: { app: web-dp-cka17-trb } }
  template:
    metadata: { labels: { app: web-dp-cka17-trb } }
    spec:
      containers:
      - name: web
        image: nginx:1.25
        command: ["/bin/bsh","-c","nginx -g 'daemon off;'"]   # typo on purpose
        ports: [ { containerPort: 80 } ]
        volumeMounts:
        - { name: web-vol, mountPath: /usr/share/nginx/html }
      volumes:
      - name: web-vol
        persistentVolumeClaim:
          claimName: web-pvc-cka17-trb
YAML
say "seeded: web-dp-cka17-trb with an oversized PVC and a bad command (Q10)"

echo
echo "   Set 1 seeded. Namespaces you may need to create yourself: secure-sys-cka12-arch, grape-cka06-str"
