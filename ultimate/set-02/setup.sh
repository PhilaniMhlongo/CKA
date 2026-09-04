#!/usr/bin/env bash
# Seeds the state Set 2 expects, faults included. Safe to re-run.
set -u
say() { printf "   %s\n" "$1"; }
apply() { kubectl apply -f - >/dev/null 2>&1; }
ns() { kubectl create namespace "$1" --dry-run=client -o yaml | kubectl apply -f - >/dev/null 2>&1; }

# ---------------------------------------------------------------- Q2 source file
mkdir -p /opt
printf 'username=admin\npassword=Str0ngP4ss\n' > /opt/db-user-pass
say "seeded: /opt/db-user-pass (Q2)"

# ---------------------------------------------------------------- Q3 PV to bind
cat <<'YAML' | apply
apiVersion: v1
kind: PersistentVolume
metadata: { name: apple-pv-cka04-str }
spec:
  capacity: { storage: 50Mi }
  accessModes: ["ReadWriteOnce"]
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath: { path: /tmp/apple-cka04-str }
YAML
say "seeded: PV apple-pv-cka04-str, 50Mi, class manual (Q3)"

# ---------------------------------------------------------------- Q5 two pods, one shared label
ns svcn-cka05
cat <<'YAML' | apply
apiVersion: v1
kind: Pod
metadata:
  name: pod-23
  namespace: svcn-cka05
  labels: { tier: backend, env: prod }
spec:
  containers: [ { name: nginx, image: nginx:1.25, ports: [ { containerPort: 80 } ] } ]
---
apiVersion: v1
kind: Pod
metadata:
  name: pod-21
  namespace: svcn-cka05
  labels: { tier: backend, env: dev }
spec:
  containers: [ { name: nginx, image: nginx:1.25, ports: [ { containerPort: 80 } ] } ]
---
apiVersion: v1
kind: Pod
metadata:
  name: pod-99
  namespace: svcn-cka05
  labels: { tier: frontend, env: prod }
spec:
  containers: [ { name: nginx, image: nginx:1.25, ports: [ { containerPort: 80 } ] } ]
YAML
say "seeded: pod-23, pod-21 (share tier=backend) and a decoy pod-99 (Q5)"

# ---------------------------------------------------------------- Q6 deployment + service for the ingress
ns svcn-cka04
cat <<'YAML' | apply
apiVersion: apps/v1
kind: Deployment
metadata: { name: nginx-deployment-cka04-svcn, namespace: svcn-cka04 }
spec:
  replicas: 1
  selector: { matchLabels: { app: nginx-cka04 } }
  template:
    metadata: { labels: { app: nginx-cka04 } }
    spec:
      containers: [ { name: nginx, image: nginx:1.25, ports: [ { containerPort: 80 } ] } ]
---
apiVersion: v1
kind: Service
metadata: { name: nginx-service-cka04-svcn, namespace: svcn-cka04 }
spec:
  selector: { app: nginx-cka04 }
  ports: [ { port: 80, targetPort: 80 } ]
YAML
say "seeded: nginx-deployment-cka04-svcn + service in svcn-cka04 (Q6)"

# ---------------------------------------------------------------- Q7 broken RBAC
ns trb-cka24
kubectl create serviceaccount thor-cka24-trb -n trb-cka24 --dry-run=client -o yaml | apply
cat <<'YAML' | apply
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata: { name: thor-role-cka24-trb, namespace: trb-cka24 }
rules:
- apiGroups: [""]
  resources: ["pod", "secret"]     # singular on purpose
  verbs: ["delete"]                 # wrong verb on purpose
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata: { name: thor-role-binding-cka24-trb, namespace: trb-cka24 }
subjects:
- kind: ServiceAccount
  name: thor-cka24-trb
  namespace: default                # wrong subject namespace on purpose
roleRef:
  kind: Role
  name: thor-role-cka24-trb
  apiGroup: rbac.authorization.k8s.io
YAML
say "seeded: thor-cka24-trb with a Role/RoleBinding carrying 3 faults (Q7)"

# ---------------------------------------------------------------- Q8 service + deployment, multiple faults
ns web-cka06-trb
cat <<'YAML' | apply
apiVersion: apps/v1
kind: Deployment
metadata: { name: web-dp-cka06-trb, namespace: web-cka06-trb }
spec:
  replicas: 1
  selector: { matchLabels: { app: web-cka06 } }
  template:
    metadata: { labels: { app: web-cka06 } }
    spec:
      containers:
      - name: web
        image: httpd:latest-fake       # image does not exist
        ports: [ { containerPort: 80 } ]
---
apiVersion: v1
kind: Service
metadata: { name: web-service-cka06-trb, namespace: web-cka06-trb }
spec:
  type: NodePort
  selector: { app: webcka06 }          # label typo: no such pod
  ports:
  - port: 80
    targetPort: 8080                   # httpd listens on 80
    nodePort: 30005
YAML
say "seeded: web-dp-cka06-trb + service with 3 faults (Q8)"

# ---------------------------------------------------------------- Q9 network policy
ns cyan-ns-cka28-trb
cat <<'YAML' | apply
apiVersion: v1
kind: Pod
metadata:
  name: cyan-pod-cka28-trb
  namespace: cyan-ns-cka28-trb
  labels: { app: cyan }
spec:
  containers: [ { name: nginx, image: nginx:1.25, ports: [ { containerPort: 80 } ] } ]
---
apiVersion: v1
kind: Service
metadata: { name: cyan-svc-cka28-trb, namespace: cyan-ns-cka28-trb }
spec:
  selector: { app: cyan }
  ports: [ { port: 80, targetPort: 80 } ]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: { name: cyan-np-cka28-trb, namespace: cyan-ns-cka28-trb }
spec:
  podSelector:
    matchLabels: { app: cyan }
  policyTypes: ["Ingress"]
  ingress:
  - from:
    - podSelector:
        matchLabels: { app: cyan-white }   # no namespaceSelector: never matches
    ports:
    - protocol: TCP
      port: 8080                            # wrong port on purpose
YAML
cat <<'YAML' | apply
apiVersion: v1
kind: Pod
metadata:
  name: cyan-white-cka28-trb1
  namespace: default
  labels: { app: cyan-white }
spec:
  containers: [ { name: c, image: busybox:1.36, command: ["sh","-c","sleep 86400"] } ]
---
apiVersion: v1
kind: Pod
metadata:
  name: cyan-black-cka28-trb
  namespace: default
  labels: { app: cyan-black }
spec:
  containers: [ { name: c, image: busybox:1.36, command: ["sh","-c","sleep 86400"] } ]
YAML
kubectl label namespace default kubernetes.io/metadata.name=default --overwrite >/dev/null 2>&1
say "seeded: cyan pod/service/policy + white and black client pods (Q9)"

# --------------------------------------------------------------- Q10 broken rollout
ns dev-wl07
cat <<'YAML' | apply
apiVersion: apps/v1
kind: Deployment
metadata: { name: app-wl07, namespace: dev-wl07 }
spec:
  replicas: 2
  selector: { matchLabels: { app: app-wl07 } }
  template:
    metadata: { labels: { app: app-wl07 } }
    spec:
      containers: [ { name: app, image: nginx:1.25 } ]
YAML
kubectl rollout status deploy/app-wl07 -n dev-wl07 --timeout=90s >/dev/null 2>&1
kubectl set image deploy/app-wl07 -n dev-wl07 app=nginx:1.99-does-not-exist >/dev/null 2>&1
say "seeded: app-wl07 rolled forward to a broken image (Q10)"

echo
echo "   Set 2 seeded."
