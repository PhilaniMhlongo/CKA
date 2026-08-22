# Set 2 — Model Answers

---

## Q1 — resource-pod (6%)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-pod
  namespace: monitoring
spec:
  containers:
  - name: nginx
    image: nginx
    resources:
      requests: {cpu: "100m", memory: "128Mi"}
      limits:   {cpu: "200m", memory: "256Mi"}
```

Generator shortcut: `kubectl run resource-pod --image=nginx -n monitoring $do > p.yaml`
then add the `resources` block.

---

## Q2 — health-check probes (8%)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: health-check
  namespace: probes
spec:
  containers:
  - name: nginx
    image: nginx
    livenessProbe:
      httpGet: {path: /, port: 80}
      initialDelaySeconds: 5
    readinessProbe:
      httpGet: {path: /, port: 80}
      initialDelaySeconds: 5
```

---

## Q3 — StorageClass + PVC (8%)

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-storage
provisioner: kubernetes.io/no-provisioner
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
  namespace: storage
spec:
  storageClassName: fast-storage
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 1Gi
```

`provisioner` sits at the top level of a StorageClass, not under `spec` — StorageClass has
no `spec` at all. Same for `volumeBindingMode` and `reclaimPolicy`.

---

## Q4 — Sidecar logging pod (10%)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: logger
  namespace: monitoring
spec:
  containers:
  - name: busybox
    image: busybox:1.36
    command: ["/bin/sh","-c"]
    args: ["while true; do echo \"$(date) - Application log entry\" >> /var/log/app.log; sleep 10; done"]
    volumeMounts:
    - name: log-volume
      mountPath: /var/log
  - name: fluentd
    image: fluentd:v1.16-1
    volumeMounts:
    - name: log-volume
      mountPath: /var/log
  volumes:
  - name: log-volume
    emptyDir: {}
```

---

## Q5 — Taints and tolerations (12%)

```bash
kubectl taint nodes node01 special-workload=true:NoSchedule
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: toleration-deploy
  namespace: scheduling
spec:
  replicas: 2
  selector:
    matchLabels:
      app: toleration-deploy
  template:
    metadata:
      labels:
        app: toleration-deploy
    spec:
      tolerations:
      - key: special-workload
        operator: Equal
        value: "true"
        effect: NoSchedule
      containers:
      - name: nginx
        image: nginx
```

`normal-deploy` is the same manifest with the name changed and the tolerations removed:

```bash
kubectl create deploy normal-deploy --image=nginx --replicas=2 -n scheduling
kubectl get pods -n scheduling -o wide     # confirm placement
```

`value: "true"` must be quoted — it's a string, and an unquoted `true` is a YAML boolean
and will be rejected.

---

## Q6 — Pod Security Admission (10%)

```bash
kubectl create ns security
kubectl label ns security podsecurity.kubernetes.io/enforce=restricted
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
  namespace: security
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: nginx
    image: nginxinc/nginx-unprivileged:1.25
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop: ["ALL"]
```

The four things `restricted` always wants: non-root, no privilege escalation, all caps
dropped, `RuntimeDefault` seccomp. If admission rejects the pod, the API error names the
exact field it disliked — read it rather than guessing.

---

## Q7 — Multi-rule RBAC (12%)

```bash
kubectl create ns cluster-admin
kubectl create sa app-admin -n cluster-admin
kubectl create role app-admin -n cluster-admin \
  --verb=list,get,watch --resource=pods
```

The imperative form only builds one rule, so write the Role as YAML:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-admin
  namespace: cluster-admin
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["list","get","watch"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["list","get","watch","update"]
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["create","delete"]
```

```bash
kubectl create rolebinding app-admin -n cluster-admin \
  --role=app-admin --serviceaccount=cluster-admin:app-admin
kubectl run admin-pod --image=busybox:1.36 -n cluster-admin \
  --overrides='{"spec":{"serviceAccountName":"app-admin"}}' -- sleep 3600
```

Deployments live in the `apps` API group; pods and configmaps live in the core group
(`""`). Getting that wrong silently produces a Role that grants nothing.

---

## Q8 — DNS debugging (12%)

```bash
kubectl create ns dns-debug
kubectl create deploy web-app --image=nginx --replicas=3 -n dns-debug
kubectl expose deploy web-app --name=web-svc --port=80 --target-port=80 -n dns-debug
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dns-test
  namespace: dns-debug
spec:
  dnsConfig:
    searches:
    - dns-debug.svc.cluster.local
  containers:
  - name: busybox
    image: busybox:1.36
    command: ["sleep","3600"]
```

```bash
kubectl exec dns-test -n dns-debug -- nslookup web-svc
kubectl exec dns-test -n dns-debug -- nslookup web-svc.dns-debug.svc.cluster.local
```

---

## Q9 — Three-tier NetworkPolicy chain (12%)

```bash
kubectl create ns network
for a in web api db; do kubectl create deploy $a --image=nginx -n network; done
```

`kubectl create deploy` labels pods `app=<name>` automatically, which is exactly what the
selectors need.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: web-policy, namespace: network}
spec:
  podSelector: {matchLabels: {app: web}}
  policyTypes: ["Egress"]
  egress:
  - to:
    - podSelector: {matchLabels: {app: api}}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: api-policy, namespace: network}
spec:
  podSelector: {matchLabels: {app: api}}
  policyTypes: ["Ingress","Egress"]
  ingress:
  - from:
    - podSelector: {matchLabels: {app: web}}
  egress:
  - to:
    - podSelector: {matchLabels: {app: db}}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: db-policy, namespace: network}
spec:
  podSelector: {matchLabels: {app: db}}
  policyTypes: ["Ingress"]
  ingress:
  - from:
    - podSelector: {matchLabels: {app: api}}
```

In the real world you'd also need egress to CoreDNS on UDP/TCP 53, otherwise name
resolution breaks inside the restricted pods. The question doesn't ask for it, but
remember it exists.

---

## Q10 — Rollout and rollback (10%)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-v1
  namespace: upgrade
spec:
  replicas: 4
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  selector:
    matchLabels:
      app: app-v1
  template:
    metadata:
      labels:
        app: app-v1
    spec:
      containers:
      - name: nginx
        image: nginx:1.19
```

```bash
kubectl set image deploy/app-v1 nginx=nginx:1.20 -n upgrade
kubectl rollout status deploy/app-v1 -n upgrade
mkdir -p /tmp/exam
kubectl rollout history deploy/app-v1 -n upgrade > /tmp/exam/rollout-history.txt
kubectl rollout undo deploy/app-v1 -n upgrade
kubectl get deploy app-v1 -n upgrade -o jsonpath='{.spec.template.spec.containers[0].image}'
```

The container name in `set image` must match the container in the pod template
(`nginx=...`), not the deployment name.
