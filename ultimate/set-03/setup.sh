#!/usr/bin/env bash
# Seeds the state Set 3 expects, faults included. Safe to re-run.
set -u
say() { printf "   %s\n" "$1"; }
apply() { kubectl apply -f - >/dev/null 2>&1; }
ns() { kubectl create namespace "$1" --dry-run=client -o yaml | kubectl apply -f - >/dev/null 2>&1; }

ns msg-cka07; ns hr-cka08; ns wl06-cka; ns trb-cka12; ns db-cka05-trb; ns blue-cka09-trb
say "seeded: namespaces for Q2, Q3, Q5, Q7, Q8, Q9"

# ---------------------------------------------------------------- Q4 PV + pod manifest
cat <<'YAML' | apply
apiVersion: v1
kind: PersistentVolume
metadata: { name: peach-pv-cka05-str }
spec:
  capacity: { storage: 150Mi }
  accessModes: ["ReadWriteOnce"]
  persistentVolumeReclaimPolicy: Retain
  storageClassName: peach-manual
  hostPath: { path: /tmp/peach-cka05-str }
YAML
mkdir -p /root
cat <<'YAML' > /root/peach-pod-cka05-str.yaml
apiVersion: v1
kind: Pod
metadata:
  name: peach-pod-cka05-str
  namespace: default
spec:
  containers:
  - name: web
    image: nginx:1.25
YAML
say "seeded: PV peach-pv-cka05-str (150Mi, class peach-manual) + /root/peach-pod-cka05-str.yaml (Q4)"

# ---------------------------------------------------------------- Q5 wrong units
kubectl delete pod nginx-wl06 -n wl06-cka --ignore-not-found --force --grace-period=0 >/dev/null 2>&1
cat <<'YAML' | apply
apiVersion: v1
kind: Pod
metadata: { name: nginx-wl06, namespace: wl06-cka }
spec:
  containers:
  - name: nginx
    image: nginx:1.25
    resources:
      requests:
        memory: "50Gi"      # should be Mi
        cpu: "100m"
      limits:
        memory: "100Gi"     # should be Mi
        cpu: "200m"
YAML
say "seeded: nginx-wl06 requesting gibibytes instead of mebibytes (Q5)"

# ---------------------------------------------------------------- Q6 requests > limits
cat <<'YAML' > /root/app-wl03.yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-wl03
  namespace: default
spec:
  containers:
  - name: app
    image: nginx:1.25
    resources:
      requests:
        memory: "1Gi"
        cpu: "500m"
      limits:
        memory: "100Mi"
        cpu: "200m"
YAML
kubectl delete pod app-wl03 --ignore-not-found --force --grace-period=0 >/dev/null 2>&1
say "seeded: /root/app-wl03.yaml with requests above limits (Q6)"

# ---------------------------------------------------------------- Q7 bad probe template
cat <<'YAML' > /root/red-probe-cka12-trb.yaml
apiVersion: v1
kind: Pod
metadata:
  name: red-probe-cka12-trb
  namespace: trb-cka12
spec:
  containers:
  - name: red
    image: busybox:1.36
    args:
    - /bin/sh
    - -c
    - touch /tmp/ready && sleep 3 && rm -f /tmp/ready && sleep 3600
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 1
      periodSeconds: 2
YAML
kubectl delete pod red-probe-cka12-trb -n trb-cka12 --ignore-not-found --force --grace-period=0 >/dev/null 2>&1
say "seeded: /root/red-probe-cka12-trb.yaml with an httpGet probe against a non-HTTP container (Q7)"

# ---------------------------------------------------------------- Q8 secret key mismatch
cat <<'YAML' | apply
apiVersion: v1
kind: Secret
metadata: { name: db-secret-cka05-trb, namespace: db-cka05-trb }
type: Opaque
stringData:
  DB_User: root
  DB_Password: Passw0rd123
---
apiVersion: apps/v1
kind: Deployment
metadata: { name: db-deployment-cka05-trb, namespace: db-cka05-trb }
spec:
  replicas: 1
  selector: { matchLabels: { app: db-cka05 } }
  template:
    metadata: { labels: { app: db-cka05 } }
    spec:
      containers:
      - name: db
        image: mysql:8.0
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-secret-cka05-trb
              key: DB_Passwd            # key does not exist: it is DB_Password
        - name: MYSQL_USER
          valueFrom:
            secretKeyRef:
              name: db-secret-cka05-trb
              key: DB_User
YAML
say "seeded: db-deployment-cka05-trb referencing a secret key that does not exist (Q8)"

# ---------------------------------------------------------------- Q9 two faults
cat <<'YAML' | apply
apiVersion: v1
kind: ConfigMap
metadata: { name: nginx-config-cka09, namespace: blue-cka09-trb }
data:
  nginx.conf: |
    events {}
    http {
      server {
        listen 80;
        location / { return 200 'blue ok\n'; }
      }
    }
---
apiVersion: apps/v1
kind: Deployment
metadata: { name: blue-dp-cka09-trb, namespace: blue-cka09-trb }
spec:
  replicas: 1
  selector: { matchLabels: { app: blue-cka09 } }
  template:
    metadata: { labels: { app: blue-cka09 } }
    spec:
      containers:
      - name: blue
        image: nginx:1.25
        command: ["/bin/sh", "nginx -g 'daemon off;'"]   # missing -c
        volumeMounts:
        - name: conf
          mountPath: /etc/nginx/nginx.conf               # directory mount, no subPath
      volumes:
      - name: conf
        configMap:
          name: nginx-config-cka09
YAML
say "seeded: blue-dp-cka09-trb missing 'sh -c' and mounting a ConfigMap without subPath (Q9)"

echo
echo "   Set 3 seeded. Q10 needs root on the controlplane node."
