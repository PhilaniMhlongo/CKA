# CKA Practice — Tasks & Solutions

---

## Question 1 — PVC + Pod (Storage)

**Task:** Create a PersistentVolumeClaim named `data-pvc` in namespace `eda9e0ec987a-storage-task` using StorageClass `standard` with 2Gi storage and ReadWriteOnce access mode. Then create a pod named `data-pod` using the nginx image that mounts the PVC at `/usr/share/nginx/html`.

**Solution:**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
  namespace: eda9e0ec987a-storage-task
spec:
  storageClassName: standard
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: data-pod
  namespace: eda9e0ec987a-storage-task
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

**Verify:**

```bash
kubectl get pvc data-pvc -n eda9e0ec987a-storage-task
kubectl get pod data-pod -n eda9e0ec987a-storage-task
```

---

## Question 2 — Default StorageClass

**Task:** Create a StorageClass named `eda9e0ec987a-fast-local` with provisioner `rancher.io/local-path` and volumeBindingMode `WaitForFirstConsumer`. Set it as the default StorageClass by adding the annotation `storageclass.kubernetes.io/is-default-class=true`.

**Solution:**

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: eda9e0ec987a-fast-local
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
```

**Verify:**

```bash
kubectl get sc eda9e0ec987a-fast-local \
  -o jsonpath='{.provisioner}|{.volumeBindingMode}|{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}' \
  | grep -qx 'rancher.io/local-path|WaitForFirstConsumer|true'
```

---

## Question 3 — Manual PV / PVC / Pod

**Task:** Create a PersistentVolume named `eda9e0ec987a-manual-pv` with 1Gi capacity, ReadWriteOnce access mode, hostPath `/mnt/data`, and nodeAffinity matching any one worker node. Create a PersistentVolumeClaim named `manual-pvc` in namespace `eda9e0ec987a-manual-storage` with storageClassName set to empty string requesting 1Gi. Create a pod named `manual-pod` using busybox (command: `sleep 3600`) that mounts the PVC at `/data`.

**Solution:**

```bash
# Find a worker node name first:
kubectl get nodes
```

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: eda9e0ec987a-manual-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /mnt/data
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - <NODE_NAME>   # replace with an actual worker node name
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: manual-pvc
  namespace: eda9e0ec987a-manual-storage
spec:
  storageClassName: ""
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: manual-pod
  namespace: eda9e0ec987a-manual-storage
spec:
  containers:
    - name: busybox
      image: busybox
      command: ["sleep", "3600"]
      volumeMounts:
        - name: data-vol
          mountPath: /data
  volumes:
    - name: data-vol
      persistentVolumeClaim:
        claimName: manual-pvc
```

---

## Question 4 — Deployment + HPA

**Task:** Create a deployment named `scaling-app` in namespace `eda9e0ec987a-scaling` with 2 replicas using nginx. Set requests cpu: 200m / memory: 256Mi and limits cpu: 500m / memory: 512Mi. Create an HPA targeting 70% average CPU utilization, min 2, max 5 replicas.

**Solution:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: scaling-app
  namespace: eda9e0ec987a-scaling
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
kubectl apply -f scaling-app.yaml
kubectl autoscale deployment scaling-app -n eda9e0ec987a-scaling \
  --min=2 --max=5 --cpu-percent=70
```

---

## Question 5 — Node Affinity

**Task:** Label any worker node with `disk=ssd`. Create a deployment `app-scheduling` in namespace `eda9e0ec987a-scheduling` with 3 replicas using nginx, with `requiredDuringSchedulingIgnoredDuringExecution` node affinity for `disk=ssd`.

**Solution:**

```bash
kubectl get nodes                      # pick a WORKER node (not control-plane)
kubectl label node <NODE_NAME> disk=ssd
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-scheduling
  namespace: eda9e0ec987a-scheduling
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
                    values:
                      - ssd
      containers:
        - name: nginx
          image: nginx
```

**Verify:**

```bash
kubectl get deployment app-scheduling -n eda9e0ec987a-scheduling \
  -o jsonpath='{.spec.template.spec.affinity.nodeAffinity}' | grep -q disk
```

---

## Question 6 — Pod Security (restricted)

**Task:** Label namespace `eda9e0ec987a-security` with `pod-security.kubernetes.io/enforce=restricted`. Create a pod `secure-pod` in that namespace that complies with the restricted policy: runAsNonRoot true, runAsUser 1000, seccompProfile RuntimeDefault, allowPrivilegeEscalation false, drop ALL capabilities. Use nginx.

**Solution:**

```bash
kubectl label namespace eda9e0ec987a-security pod-security.kubernetes.io/enforce=restricted
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
  namespace: eda9e0ec987a-security
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: nginx
      image: nginx
      securityContext:
        allowPrivilegeEscalation: false
        capabilities:
          drop:
            - ALL
```

> Note: stock `nginx` cannot actually serve as UID 1000 (it may CrashLoop); the graded check is usually manifest compliance. In real life you'd use `nginxinc/nginx-unprivileged`.

---

## Question 7 — Taints & Tolerations

**Task:** Taint any worker node with `special-workload=true:NoSchedule`. Create `toleration-deploy` (2 replicas, nginx) in `eda9e0ec987a-scheduling` with a matching toleration, and `normal-deploy` (2 replicas, nginx) without one. Verify `normal-deploy` pods do not schedule on the tainted node.

**Solution:**

```bash
kubectl get nodes                      # pick a worker node
kubectl taint nodes <NODE_NAME> special-workload=true:NoSchedule
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: toleration-deploy
  namespace: eda9e0ec987a-scheduling
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
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: normal-deploy
  namespace: eda9e0ec987a-scheduling
spec:
  replicas: 2
  selector:
    matchLabels:
      app: normal-deploy
  template:
    metadata:
      labels:
        app: normal-deploy
    spec:
      containers:
        - name: nginx
          image: nginx
```

**Verify:**

```bash
kubectl get pods -n eda9e0ec987a-scheduling -o wide
```

---

## Question 8 — Headless Service + StatefulSet

**Task:** Create namespace `eda9e0ec987a-stateful`. Create a headless Service `web-svc` (clusterIP None, selector `app=web`). Create a StatefulSet `web` with 3 replicas using nginx, serviceName `web-svc`, with a volumeClaimTemplate named `www` requesting 1Gi from StorageClass `cold`, mounted at `/usr/share/nginx/html`.

**Solution:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-svc
  namespace: eda9e0ec987a-stateful
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
  namespace: eda9e0ec987a-stateful
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
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 1Gi
```

**Verify:**

```bash
kubectl get svc web-svc -n eda9e0ec987a-stateful -o jsonpath='{.spec.clusterIP}' | grep -q None
```

---

## Question 9 — DNS Debugging (dnsConfig)

**Task:** Create deployment `web-app` (3 replicas, nginx) in namespace `eda9e0ec987a-dns-debug`. Create ClusterIP service `web-svc` targeting it. Create a debug pod `dns-test` (busybox, `sleep 3600`) with custom dnsConfig adding search domain `eda9e0ec987a-dns-debug.svc.cluster.local`. From `dns-test`, verify it resolves `web-svc` and the FQDN.

**Solution:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: eda9e0ec987a-dns-debug
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
        - name: nginx
          image: nginx
---
apiVersion: v1
kind: Service
metadata:
  name: web-svc
  namespace: eda9e0ec987a-dns-debug
spec:
  selector:
    app: web-app
  ports:
    - port: 80
      targetPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: dns-test
  namespace: eda9e0ec987a-dns-debug
spec:
  dnsConfig:
    searches:
      - eda9e0ec987a-dns-debug.svc.cluster.local   # must match the REAL namespace
  containers:
    - name: busybox
      image: busybox
      command: ["sleep", "3600"]
```

**Verify:**

```bash
kubectl exec dns-test -n eda9e0ec987a-dns-debug -- nslookup web-svc
kubectl exec dns-test -n eda9e0ec987a-dns-debug -- nslookup web-svc.eda9e0ec987a-dns-debug.svc.cluster.local
```

---

## Question 10 — DNS Test to File

**Task:** Create deployment `dns-app` (2 replicas, nginx) and ClusterIP service `dns-svc` in namespace `eda9e0ec987a-dns-config`. Create pod `dns-tester` using `infoblox/dnstools` that runs nslookup on `dns-svc` and its FQDN, saving results to `/tmp/dns-test.txt`.

**Solution:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dns-app
  namespace: eda9e0ec987a-dns-config
spec:
  replicas: 2
  selector:
    matchLabels:
      app: dns-app
  template:
    metadata:
      labels:
        app: dns-app
    spec:
      containers:
        - name: nginx
          image: nginx
---
apiVersion: v1
kind: Service
metadata:
  name: dns-svc
  namespace: eda9e0ec987a-dns-config
spec:
  selector:
    app: dns-app
  ports:
    - port: 80
      targetPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: dns-tester
  namespace: eda9e0ec987a-dns-config
spec:
  containers:
    - name: dnstools
      image: infoblox/dnstools
      command:
        - sh
        - -c
        - "nslookup dns-svc > /tmp/dns-test.txt && nslookup dns-svc.eda9e0ec987a-dns-config.svc.cluster.local >> /tmp/dns-test.txt && sleep 3600"
```

**Verify:**

```bash
kubectl exec dns-tester -n eda9e0ec987a-dns-config -- cat /tmp/dns-test.txt
```

---

## Question 11 — Helm Install

**Task:** Add the Bitnami Helm repository. Install the nginx chart as release `web-release` in namespace `eda9e0ec987a-helm-test` with `service.type=NodePort` and `replicaCount=2`.

**Solution:**

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install web-release bitnami/nginx \
  --namespace eda9e0ec987a-helm-test --create-namespace \
  --set service.type=NodePort \
  --set replicaCount=2
```

**Verify:**

```bash
helm list -n eda9e0ec987a-helm-test
kubectl get pods,svc -n eda9e0ec987a-helm-test
```

---

## Question 12 — Kustomize Base + Overlay

**Task:** Create a Kustomize structure at `/tmp/exam/kustomize/` with a base (nginx deployment, 2 replicas) and a production overlay that sets replicas to 3, adds label `environment=production`, and generates a ConfigMap from an `index.html` file. Apply the overlay to namespace `eda9e0ec987a-kustomize`.

**Solution:**

```bash
mkdir -p /tmp/exam/kustomize/base
mkdir -p /tmp/exam/kustomize/overlays/production
```

`/tmp/exam/kustomize/base/deployment.yaml`:

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

`/tmp/exam/kustomize/base/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
```

`/tmp/exam/kustomize/overlays/production/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../base
namespace: eda9e0ec987a-kustomize
replicas:
  - name: nginx
    count: 3
commonLabels:
  environment: production
configMapGenerator:
  - name: web-content
    files:
      - index.html
```

```bash
echo '<html><body><h1>Production</h1></body></html>' > /tmp/exam/kustomize/overlays/production/index.html
kubectl create namespace eda9e0ec987a-kustomize
kubectl apply -k /tmp/exam/kustomize/overlays/production/
```

> Note: newer kustomize versions prefer the `labels:` field over the deprecated `commonLabels:`, but `commonLabels` still works and is fine for a fresh apply.

---

## Question 13 — Gateway API

**Task:** Create a Gateway `main-gateway` in namespace `eda9e0ec987a-gateway` with an HTTP listener on port 80. Create an HTTPRoute `app-routes` routing `/app1` → `app1-svc:8080` and `/app2` → `app2-svc:8080`. Create both backing deployments (nginx) and services.

**Solution:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app1
  namespace: eda9e0ec987a-gateway
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app1
  template:
    metadata:
      labels:
        app: app1
    spec:
      containers:
        - name: nginx
          image: nginx
---
apiVersion: v1
kind: Service
metadata:
  name: app1-svc
  namespace: eda9e0ec987a-gateway
spec:
  selector:
    app: app1
  ports:
    - port: 8080
      targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app2
  namespace: eda9e0ec987a-gateway
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app2
  template:
    metadata:
      labels:
        app: app2
    spec:
      containers:
        - name: nginx
          image: nginx
---
apiVersion: v1
kind: Service
metadata:
  name: app2-svc
  namespace: eda9e0ec987a-gateway
spec:
  selector:
    app: app2
  ports:
    - port: 8080
      targetPort: 80
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: main-gateway
  namespace: eda9e0ec987a-gateway
spec:
  gatewayClassName: example   # check `kubectl get gatewayclass` and use the one in the cluster
  listeners:
    - name: http
      protocol: HTTP
      port: 80
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: app-routes
  namespace: eda9e0ec987a-gateway
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

---

## Question 14 — LimitRange + ResourceQuota

**Task:** Create a LimitRange `resource-limits` in namespace `eda9e0ec987a-limits` with container defaults (cpu 200m / memory 256Mi), default requests (cpu 100m / memory 128Mi), and max limits (cpu 500m / memory 512Mi). Create ResourceQuota `compute-quota` with hard limits cpu=2, memory=2Gi, pods=5. Create deployment `test-limits` with 2 replicas using nginx (no explicit resources).

**Solution:**

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: resource-limits
  namespace: eda9e0ec987a-limits
spec:
  limits:
    - type: Container
      default:
        cpu: 200m
        memory: 256Mi
      defaultRequest:
        cpu: 100m
        memory: 128Mi
      max:
        cpu: 500m
        memory: 512Mi
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: eda9e0ec987a-limits
spec:
  hard:
    cpu: "2"
    memory: 2Gi
    pods: "5"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-limits
  namespace: eda9e0ec987a-limits
spec:
  replicas: 2
  selector:
    matchLabels:
      app: test-limits
  template:
    metadata:
      labels:
        app: test-limits
    spec:
      containers:
        - name: nginx
          image: nginx
```

---

## Question 15 — Resource Consumer + HPA

**Task:** Create deployment `resource-consumer` in namespace `eda9e0ec987a-monitoring` with 3 replicas using `gcr.io/kubernetes-e2e-test-images/resource-consumer:1.5`. Requests cpu 100m / memory 128Mi, limits cpu 200m / memory 256Mi. Create an HPA at 50% CPU, min 3, max 6.

**Solution:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resource-consumer
  namespace: eda9e0ec987a-monitoring
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
          image: gcr.io/kubernetes-e2e-test-images/resource-consumer:1.5
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 200m
              memory: 256Mi
```

```bash
kubectl apply -f resource-consumer.yaml
kubectl autoscale deployment resource-consumer -n eda9e0ec987a-monitoring \
  --min=3 --max=6 --cpu-percent=50
```

---

## Question 16 — RBAC (Role / RoleBinding / SA)

**Task:** Create ServiceAccount `app-admin` in namespace `eda9e0ec987a-cluster-admin`. Create Role `app-admin` allowing: list/get/watch on pods; list/get/watch/update on deployments; create/delete on configmaps. Create RoleBinding `app-admin` binding the role to the service account. Create pod `admin-pod` using `bitnami/kubectl:latest` with the `app-admin` ServiceAccount (command: `sleep 3600`).

**Solution:**

```bash
kubectl create namespace eda9e0ec987a-cluster-admin
kubectl create serviceaccount app-admin -n eda9e0ec987a-cluster-admin
```

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-admin
  namespace: eda9e0ec987a-cluster-admin
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["list", "get", "watch"]
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["list", "get", "watch", "update"]
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["create", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-admin
  namespace: eda9e0ec987a-cluster-admin
subjects:
  - kind: ServiceAccount
    name: app-admin
    namespace: eda9e0ec987a-cluster-admin
roleRef:
  kind: Role
  name: app-admin
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: v1
kind: Pod
metadata:
  name: admin-pod
  namespace: eda9e0ec987a-cluster-admin
spec:
  serviceAccountName: app-admin
  containers:
    - name: kubectl
      image: bitnami/kubectl:latest
      command: ["sleep", "3600"]
```

**Verify:**

```bash
kubectl auth can-i list pods --as=system:serviceaccount:eda9e0ec987a-cluster-admin:app-admin -n eda9e0ec987a-cluster-admin
```

---

## Question 17 — Tiered NetworkPolicies (web → api → db)

**Task:** Create deployments `web`, `api`, and `db` (1 replica each, nginx) in namespace `eda9e0ec987a-network`, each labelled `app=<name>`. Create three NetworkPolicies: `web-policy` (web egress only to api), `api-policy` (api ingress from web, egress to db), `db-policy` (db ingress only from api).

**Solution:**

```bash
kubectl create namespace eda9e0ec987a-network
kubectl create deployment web --image=nginx -n eda9e0ec987a-network
kubectl create deployment api --image=nginx -n eda9e0ec987a-network
kubectl create deployment db  --image=nginx -n eda9e0ec987a-network
# `kubectl create deployment <name>` sets label app=<name> automatically
```

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-policy
  namespace: eda9e0ec987a-network
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
    - Egress
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: api
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-policy
  namespace: eda9e0ec987a-network
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: web
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: db
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-policy
  namespace: eda9e0ec987a-network
spec:
  podSelector:
    matchLabels:
      app: db
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: api
```

---

## Question 18 — Rolling Update + Rollback

**Task:** Create deployment `app-v1` in namespace `eda9e0ec987a-upgrade` with 4 replicas using nginx:1.19, RollingUpdate strategy with maxUnavailable=1 and maxSurge=1. Update the image to nginx:1.20, save rollout history to `/tmp/exam/rollout-history.txt`, then rollback to nginx:1.19.

**Solution:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-v1
  namespace: eda9e0ec987a-upgrade
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
kubectl apply -f app-v1.yaml
kubectl set image deployment/app-v1 nginx=nginx:1.20 -n eda9e0ec987a-upgrade
kubectl rollout status deployment/app-v1 -n eda9e0ec987a-upgrade
mkdir -p /tmp/exam
kubectl rollout history deployment/app-v1 -n eda9e0ec987a-upgrade > /tmp/exam/rollout-history.txt
kubectl rollout undo deployment/app-v1 -n eda9e0ec987a-upgrade
```

---

## Question 19 — PriorityClasses + Pod Anti-Affinity

**Task:** Create PriorityClasses `eda9e0ec987a-high-priority` (value 1000) and `eda9e0ec987a-low-priority` (value 100), both globalDefault false and preemptionPolicy PreemptLowerPriority. Create pods `high-priority` and `low-priority` in namespace `eda9e0ec987a-scheduling` using nginx with the matching priorityClassName, each with required podAntiAffinity so they never land on the same node.

**Solution:**

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: eda9e0ec987a-high-priority
value: 1000
globalDefault: false
preemptionPolicy: PreemptLowerPriority
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: eda9e0ec987a-low-priority
value: 100
globalDefault: false
preemptionPolicy: PreemptLowerPriority
---
apiVersion: v1
kind: Pod
metadata:
  name: high-priority
  namespace: eda9e0ec987a-scheduling
  labels:
    priority: high
spec:
  priorityClassName: eda9e0ec987a-high-priority
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels:
              priority: low
          topologyKey: kubernetes.io/hostname
  containers:
    - name: nginx
      image: nginx
---
apiVersion: v1
kind: Pod
metadata:
  name: low-priority
  namespace: eda9e0ec987a-scheduling
  labels:
    priority: low
spec:
  priorityClassName: eda9e0ec987a-low-priority
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels:
              priority: high
          topologyKey: kubernetes.io/hostname
  containers:
    - name: nginx
      image: nginx
```

---

## Question 20 — Troubleshoot a Broken Deployment

**Task:** In namespace `eda9e0ec987a-troubleshoot`, the deployment `failing-app` has three issues: containerPort is 8080 instead of 80, memory limit is too low at 32Mi, and the liveness probe points to port 8080. Fix all three: containerPort 80, memory limit 256Mi, liveness probe port 80.

**Solution:**

```bash
kubectl patch deployment failing-app -n eda9e0ec987a-troubleshoot --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/ports/0/containerPort", "value": 80},
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/limits/memory", "value": "256Mi"},
  {"op": "replace", "path": "/spec/template/spec/containers/0/livenessProbe/httpGet/port", "value": 80}
]'
kubectl rollout status deployment/failing-app -n eda9e0ec987a-troubleshoot --timeout=120s
```

> Alternative: `kubectl edit deployment failing-app -n eda9e0ec987a-troubleshoot` and change the three values by hand.

---

## Question 21 — Simple Pod with Label

**Task:** In namespace `7b43d4b5300b-app-team1`, create a pod named `nginx-pod` with image nginx:1.19 and label `run=nginx-pod`.

**Solution:**

```bash
kubectl run nginx-pod --image=nginx:1.19 -n 7b43d4b5300b-app-team1 --labels=run=nginx-pod
```

**Verify:**

```bash
kubectl get pod nginx-pod -n 7b43d4b5300b-app-team1 --show-labels
```

---

## Question 22 — DaemonSet with hostPath + Tolerate All Taints

**Task:** In namespace `7b43d4b5300b-logging`, create a DaemonSet `log-collector` using busybox:1.36 running `while true; do echo collecting logs from $(hostname); sleep 60; done`. Mount host path `/var/log` as volume `host-logs` at `/host-logs` (readOnly). Tolerate all taints so it runs on every node.

**Solution:**

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: log-collector
  namespace: 7b43d4b5300b-logging
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
        - operator: Exists    # tolerates ALL taints
      containers:
        - name: log-collector
          image: busybox:1.36
          command: ["/bin/sh", "-c", "while true; do echo collecting logs from $(hostname); sleep 60; done"]
          volumeMounts:
            - name: host-logs
              mountPath: /host-logs
              readOnly: true
      volumes:
        - name: host-logs
          hostPath:
            path: /var/log
```

**Verify:**

```bash
kubectl get daemonset log-collector -n 7b43d4b5300b-logging -o jsonpath='{.status.desiredNumberScheduled}' | grep -qE '[1-9]'
kubectl get daemonset log-collector -n 7b43d4b5300b-logging -o jsonpath='{.spec.template.spec.volumes[0].hostPath.path}' | grep -q '/var/log'
```

---

## Question 23 — StorageClass + PVC (no-provisioner)

**Task:** Create namespace `7b43d4b5300b-storage`. Create a StorageClass `7b43d4b5300b-fast-storage` with provisioner `kubernetes.io/no-provisioner`. Create a PVC `data-pvc` in namespace `7b43d4b5300b-storage` using that StorageClass, requesting 1Gi with ReadWriteOnce.

**Solution:**

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: 7b43d4b5300b-fast-storage
provisioner: kubernetes.io/no-provisioner
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
  namespace: 7b43d4b5300b-storage
spec:
  storageClassName: 7b43d4b5300b-fast-storage
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

**Verify:**

```bash
kubectl get sc 7b43d4b5300b-fast-storage -o jsonpath='{.provisioner}' | grep -qx 'kubernetes.io/no-provisioner'
kubectl get pvc data-pvc -n 7b43d4b5300b-storage
```

> Note: with `no-provisioner` the PVC stays `Pending` until a matching PV exists — that's expected.

---

## Question 24 — Multi-Container Pod (shared emptyDir)

**Task:** Create a pod `logger` in namespace `7b43d4b5300b-monitoring` with two containers: a busybox container writing timestamped log entries to `/var/log/app.log` every 10 seconds, and a fluentd container reading from the same location. Share via an emptyDir volume.

**Solution:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: logger
  namespace: 7b43d4b5300b-monitoring
spec:
  containers:
    - name: busybox
      image: busybox
      command: ["/bin/sh", "-c"]
      args:
        - while true; do echo "$(date) - Application log entry" >> /var/log/app.log; sleep 10; done
      volumeMounts:
        - name: log-volume
          mountPath: /var/log
    - name: fluentd
      image: fluentd
      volumeMounts:
        - name: log-volume
          mountPath: /var/log
  volumes:
    - name: log-volume
      emptyDir: {}
```

**Verify:**

```bash
kubectl get pod logger -n 7b43d4b5300b-monitoring -o jsonpath='{.status.phase}' | grep -q Running
kubectl exec logger -n 7b43d4b5300b-monitoring -c fluentd -- tail /var/log/app.log
```

---

## Question 25 — RBAC in default Namespace

**Task:** Create a ServiceAccount `app-sa` in the default namespace. Create a Role `pod-reader` allowing get and list on pods. Create a RoleBinding `read-pods` binding the Role to the ServiceAccount.

**Solution:**

```bash
kubectl create serviceaccount app-sa
```

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: default
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
  - kind: ServiceAccount
    name: app-sa
    namespace: default
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

**Verify:**

```bash
kubectl get sa app-sa
kubectl get role pod-reader
kubectl get rolebinding read-pods
kubectl auth can-i list pods --as=system:serviceaccount:default:app-sa
```

---

## Question 26 — NetworkPolicy with Port

**Task:** Create namespace `7b43d4b5300b-networking`. Create a NetworkPolicy `db-policy` allowing ingress to pods with label `role=db` only from pods with label `role=frontend` on TCP port 3306.

**Solution:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-policy
  namespace: 7b43d4b5300b-networking
spec:
  podSelector:
    matchLabels:
      role: db
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              role: frontend
      ports:
        - protocol: TCP
          port: 3306
```

**Verify:**

```bash
kubectl get networkpolicy db-policy -n 7b43d4b5300b-networking
```

---

## Question 27 — Deployment + NodePort Service

**Task:** Create a Deployment `web-app` with 3 replicas using nginx:1.19 and a NodePort Service `web-service` exposing port 80 targeting the deployment.

**Solution:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
        - name: nginx
          image: nginx:1.19
---
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  type: NodePort
  selector:
    app: web-app
  ports:
    - port: 80
      targetPort: 80
```

**Verify:**

```bash
kubectl get deployment web-app
kubectl get svc web-service -o jsonpath='{.spec.type}' | grep -q NodePort
```

---

## Question 28 — Pod with Resource Requests/Limits

**Task:** Create a pod `resource-pod` in namespace `7b43d4b5300b-monitoring` using nginx with CPU request 100m, memory request 128Mi, CPU limit 200m, and memory limit 256Mi.

**Solution:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-pod
  namespace: 7b43d4b5300b-monitoring
spec:
  containers:
    - name: nginx
      image: nginx
      resources:
        requests:
          cpu: "100m"
          memory: "128Mi"
        limits:
          cpu: "200m"
          memory: "256Mi"
```

**Verify:**

```bash
kubectl get pod resource-pod -n 7b43d4b5300b-monitoring
```

---

## Question 29 — ConfigMap as Volume

**Task:** Create a ConfigMap `app-config` with key `APP_COLOR=blue`. Create a pod `config-pod` using nginx that mounts the ConfigMap as a volume at `/etc/config`.

**Solution:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  APP_COLOR: blue
---
apiVersion: v1
kind: Pod
metadata:
  name: config-pod
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

**Verify:**

```bash
kubectl exec config-pod -- cat /etc/config/APP_COLOR | grep -q blue
```

---

## Question 30 — Liveness + Readiness Probes

**Task:** Create a pod `health-check` using nginx with a liveness probe (HTTP GET `/` on port 80, initialDelaySeconds 5) and a readiness probe (HTTP GET `/` on port 80, initialDelaySeconds 5).

**Solution:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: health-check
spec:
  containers:
    - name: nginx
      image: nginx
      livenessProbe:
        httpGet:
          path: /
          port: 80
        initialDelaySeconds: 5
      readinessProbe:
        httpGet:
          path: /
          port: 80
        initialDelaySeconds: 5
```

**Verify:**

```bash
kubectl get pod health-check
```
