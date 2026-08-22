# Set 3 — Model Answers (Advanced)

---

## Q1 — Default StorageClass (7%)

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-local
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
```

The annotation value must be the quoted string `"true"`.

---

## Q2 — Static PV with node affinity (10%)

```bash
kubectl get nodes -o jsonpath='{.items[*].metadata.name}'
```

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: manual-pv
spec:
  capacity:
    storage: 1Gi
  accessModes: ["ReadWriteOnce"]
  hostPath:
    path: /mnt/data
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values: ["node01"]          # <- your node name
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: manual-pvc
  namespace: manual-storage
spec:
  storageClassName: ""
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: manual-pod
  namespace: manual-storage
spec:
  containers:
  - name: busybox
    image: busybox:1.36
    command: ["sleep","3600"]
    volumeMounts:
    - name: data-vol
      mountPath: /data
  volumes:
  - name: data-vol
    persistentVolumeClaim:
      claimName: manual-pvc
```

PV nodeAffinity is `spec.nodeAffinity.required` — no `requiredDuringScheduling...` here.
That long name is pod-only. `storageClassName: ""` explicitly opts out of the default
class; omitting the field entirely would silently pull in `fast-local` from Q1.

---

## Q3 — Headless Service + StatefulSet (10%)

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: cold
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
---
apiVersion: v1
kind: Service
metadata:
  name: web-svc
  namespace: stateful
spec:
  clusterIP: None
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
  namespace: stateful
spec:
  replicas: 3
  serviceName: web-svc
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      storageClassName: cold
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 1Gi
```

`volumeClaimTemplates` is a sibling of `template`, not nested inside it. The
`volumeMounts` name must equal the claim template's `metadata.name`.

---

## Q4 — LimitRange and ResourceQuota (10%)

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: resource-limits
  namespace: limits
spec:
  limits:
  - type: Container
    default:        {cpu: 200m, memory: 256Mi}
    defaultRequest: {cpu: 100m, memory: 128Mi}
    max:            {cpu: 500m, memory: 512Mi}
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: limits
spec:
  hard:
    cpu: "2"
    memory: 2Gi
    pods: "5"
```

```bash
kubectl create deploy test-limits --image=nginx --replicas=2 -n limits
kubectl get pods -n limits -o jsonpath='{.items[0].spec.containers[0].resources}'
```

`default` = limits, `defaultRequest` = requests. Order matters because a ResourceQuota on
`cpu`/`memory` would otherwise reject any pod that declares no resources — the LimitRange
is what makes the bare Deployment admissible.

---

## Q5 — resource-consumer + HPA (8%)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resource-consumer
  namespace: consumer
spec:
  replicas: 3
  selector:
    matchLabels:
      app: resource-consumer
  template:
    metadata:
      labels:
        app: resource-consumer
    spec:
      containers:
      - name: resource-consumer
        image: registry.k8s.io/e2e-test-images/resource-consumer:1.13
        resources:
          requests: {cpu: 100m, memory: 128Mi}
          limits:   {cpu: 200m, memory: 256Mi}
```

```bash
kubectl autoscale deploy resource-consumer -n consumer --min=3 --max=6 --cpu-percent=50
```

---

## Q6 — PriorityClasses and anti-affinity (10%)

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata: {name: high-priority}
value: 1000
globalDefault: false
preemptionPolicy: PreemptLowerPriority
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata: {name: low-priority}
value: 100
globalDefault: false
preemptionPolicy: PreemptLowerPriority
---
apiVersion: v1
kind: Pod
metadata:
  name: high-priority-pod
  namespace: priority
  labels: {priority: high}
spec:
  priorityClassName: high-priority
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchLabels: {priority: low}
        topologyKey: kubernetes.io/hostname
  containers:
  - name: nginx
    image: nginx
---
apiVersion: v1
kind: Pod
metadata:
  name: low-priority-pod
  namespace: priority
  labels: {priority: low}
spec:
  priorityClassName: low-priority
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchLabels: {priority: high}
        topologyKey: kubernetes.io/hostname
  containers:
  - name: nginx
    image: nginx
```

`value`, `globalDefault` and `preemptionPolicy` are top-level fields on a PriorityClass.
On a single-node cluster the second pod stays Pending — that is the anti-affinity working.

---

## Q7 — dnstools pod (8%)

```bash
kubectl create ns dns-config
kubectl create deploy dns-app --image=nginx --replicas=2 -n dns-config
kubectl expose deploy dns-app --name=dns-svc --port=80 --target-port=80 -n dns-config
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dns-tester
  namespace: dns-config
spec:
  containers:
  - name: dnstools
    image: infoblox/dnstools
    command:
    - sh
    - -c
    - "nslookup dns-svc > /tmp/dns-test.txt && nslookup dns-svc.dns-config.svc.cluster.local >> /tmp/dns-test.txt && sleep 3600"
```

The trailing `sleep` matters: without it the container exits and you can't `exec` in to
read the file.

---

## Q8 — Kustomize (12%)

```bash
mkdir -p /tmp/exam/kustomize/base /tmp/exam/kustomize/overlays/production
```

`base/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
```

`base/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
```

```bash
echo '<html><body><h1>Production</h1></body></html>' > /tmp/exam/kustomize/overlays/production/index.html
```

`overlays/production/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../base
namespace: kustomize
replicas:
  - name: nginx
    count: 3
labels:
  - pairs:
      environment: production
    includeSelectors: false
configMapGenerator:
  - name: web-content
    files:
      - index.html
```

```bash
kubectl create ns kustomize
kubectl kustomize /tmp/exam/kustomize/overlays/production/   # dry-run: always look first
kubectl apply -k /tmp/exam/kustomize/overlays/production/
```

`commonLabels: {environment: production}` also works and is shorter, but it injects the
label into the selector too, which makes the overlay non-updatable in place. `labels:`
with `includeSelectors: false` is the modern form.

---

## Q9 — Helm (10%)

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install web-release bitnami/nginx \
  --namespace helm-test --create-namespace \
  --set service.type=NodePort \
  --set replicaCount=2

helm list -n helm-test
helm get values web-release -n helm-test
```

If the install fails on chart resolution, `helm repo update` again — a stale index is the
usual cause. Pods failing to pull images is a Bitnami registry issue, not a mistake in
your command.

---

## Q10 — Gateway API (15%)

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/latest/download/standard-install.yaml
kubectl create ns gateway
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata: {name: app1, namespace: gateway}
spec:
  replicas: 1
  selector: {matchLabels: {app: app1}}
  template:
    metadata: {labels: {app: app1}}
    spec:
      containers:
      - name: nginx
        image: nginx
---
apiVersion: v1
kind: Service
metadata: {name: app1-svc, namespace: gateway}
spec:
  selector: {app: app1}
  ports:
  - port: 8080
    targetPort: 80
```

(Repeat both for `app2` / `app2-svc`.)

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: main-gateway
  namespace: gateway
spec:
  gatewayClassName: example
  listeners:
  - name: http
    protocol: HTTP
    port: 80
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: app-routes
  namespace: gateway
spec:
  parentRefs:
  - name: main-gateway
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /app1
    backendRefs:
    - name: app1-svc
      port: 8080
  - matches:
    - path:
        type: PathPrefix
        value: /app2
    backendRefs:
    - name: app2-svc
      port: 8080
```

Two separate list items under `rules` — one rule per path. Nesting both `matches` under a
single rule with both `backendRefs` would load-balance across the two services instead of
routing by path. The Gateway stays `Unknown`/not Programmed without a controller; that's
expected here.
