# Set 1 — Model Answers

> Don't read this before you've been marked.

---

## Q1 — nginx-pod (5%)

```bash
kubectl create ns app-team1
kubectl run nginx-pod --image=nginx:1.19 -n app-team1 --labels=run=nginx-pod
```

`kubectl run` already applies `run=<name>`, but stating it explicitly costs nothing and
protects you when the required label differs from the pod name.

---

## Q2 — ConfigMap as a volume (8%)

```bash
kubectl create ns config
kubectl create cm app-config --from-literal=APP_COLOR=blue -n config
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: config-pod
  namespace: config
spec:
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
  volumes:
  - name: config-volume
    configMap:
      name: app-config
```

Each key becomes a file: `/etc/config/APP_COLOR` contains `blue`.
Mounting as a volume ≠ `envFrom` — read the verb in the question carefully.

---

## Q3 — PVC + consuming pod (10%)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
  namespace: storage-task
spec:
  storageClassName: standard
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 2Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: data-pod
  namespace: storage-task
spec:
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: data-volume
      mountPath: /usr/share/nginx/html
  volumes:
  - name: data-volume
    persistentVolumeClaim:
      claimName: data-pvc
```

---

## Q4 — Deployment + NodePort (10%)

```bash
kubectl create ns web
kubectl create deploy web-app --image=nginx:1.19 --replicas=3 -n web
kubectl expose deploy web-app -n web --name=web-service \
  --type=NodePort --port=80 --target-port=80
```

`kubectl expose` copies the Deployment's selector for you — that's why it's faster and
safer than hand-writing the Service.

---

## Q5 — NetworkPolicy (10%)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-policy
  namespace: networking
spec:
  podSelector:
    matchLabels:
      role: db
  policyTypes: ["Ingress"]
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: frontend
    ports:
    - protocol: TCP
      port: 3306
```

Watch the indentation trap: `ports` is a sibling of `from` inside the same ingress rule.
Putting it under `from` is the single most common mistake on this question.

---

## Q6 — RBAC (10%)

```bash
kubectl create ns rbac
kubectl create sa app-sa -n rbac
kubectl create role pod-reader --verb=get,list --resource=pods -n rbac
kubectl create rolebinding read-pods --role=pod-reader \
  --serviceaccount=rbac:app-sa -n rbac

# self-check, exactly what the marker does
kubectl auth can-i list pods -n rbac --as=system:serviceaccount:rbac:app-sa
```

---

## Q7 — Deployment with resources + HPA (12%)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: scaling-app
  namespace: scaling
spec:
  replicas: 2
  selector:
    matchLabels:
      app: scaling-app
  template:
    metadata:
      labels:
        app: scaling-app
    spec:
      containers:
      - name: nginx
        image: nginx
        resources:
          requests:
            cpu: 200m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
```

```bash
kubectl autoscale deploy scaling-app -n scaling --min=2 --max=5 --cpu-percent=70
```

---

## Q8 — Node affinity (12%)

```bash
kubectl label node node01 disk=ssd
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-scheduling
  namespace: scheduling
spec:
  replicas: 3
  selector:
    matchLabels:
      app: app-scheduling
  template:
    metadata:
      labels:
        app: app-scheduling
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: disk
                operator: In
                values: ["ssd"]
      containers:
      - name: nginx
        image: nginx
```

`nodeSelectorTerms` are OR'd; `matchExpressions` inside one term are AND'd. Note that
`requiredDuringScheduling...` takes `nodeSelectorTerms` while the `preferred` variant
takes a list of weighted `preference` objects — different shapes.

---

## Q9 — DaemonSet with hostPath (12%)

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: log-collector
  namespace: logging
spec:
  selector:
    matchLabels:
      app: log-collector
  template:
    metadata:
      labels:
        app: log-collector
    spec:
      tolerations:
      - operator: Exists          # tolerates every taint, including control-plane
      containers:
      - name: log-collector
        image: busybox:1.36
        command: ["/bin/sh","-c","while true; do echo collecting logs from $(hostname); sleep 60; done"]
        volumeMounts:
        - name: host-logs
          mountPath: /host-logs
          readOnly: true
      volumes:
      - name: host-logs
        hostPath:
          path: /var/log
```

A bare `- operator: Exists` with no key and no effect is the "tolerate everything" form.

---

## Q10 — Troubleshooting (11%)

```bash
kubectl -n troubleshoot describe deploy failing-app
kubectl -n troubleshoot get pods
kubectl -n troubleshoot describe pod <pod>   # OOMKilled + probe failures
```

Fastest fix:

```bash
kubectl patch deployment failing-app -n troubleshoot --type=json -p='[
 {"op":"replace","path":"/spec/template/spec/containers/0/ports/0/containerPort","value":80},
 {"op":"replace","path":"/spec/template/spec/containers/0/resources/limits/memory","value":"256Mi"},
 {"op":"replace","path":"/spec/template/spec/containers/0/livenessProbe/httpGet/port","value":80}
]'
kubectl rollout status deploy/failing-app -n troubleshoot --timeout=120s
```

`kubectl edit deploy failing-app -n troubleshoot` works too and is easier to remember
under pressure. The symptoms map cleanly: `OOMKilled` → memory limit; repeated
`Liveness probe failed: connection refused` → probe port; nginx listens on 80, not 8080.
