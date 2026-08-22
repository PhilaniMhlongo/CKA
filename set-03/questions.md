# CKA Practice Exam — Set 3 (Advanced)

**Duration: 60 minutes · 10 questions · 100 points · cut score 66%**

Domains covered: Storage (PV/PVC/StatefulSet), Workloads & Scheduling (quotas,
priority, affinity), Cluster Architecture (Helm, Kustomize), Services & Networking
(Gateway API, DNS).

> Allowed reference: kubernetes.io/docs and helm.sh/docs only.
> This is the hardest set — budget your time and skip aggressively.
> Suggested order: 1, 2, 4, 5, 6, 7, 3, 8, 9, 10.

---

## Question 1 — 7%

**Context:** `kubectl config use-context kubernetes-admin@kubernetes`

Create a StorageClass named `fast-local` with:

- provisioner `rancher.io/local-path`
- `volumeBindingMode: WaitForFirstConsumer`
- marked as the **default** StorageClass via the annotation
  `storageclass.kubernetes.io/is-default-class: "true"`

---

## Question 2 — 10%

**Context:** `kubectl config use-context kubernetes-admin@kubernetes`

Create a statically provisioned volume:

- A PersistentVolume named `manual-pv`: `1Gi`, `ReadWriteOnce`, `hostPath` at `/mnt/data`,
  with **nodeAffinity** pinning it to one specific node in the cluster
  (use `kubectl get nodes` to choose one).
- In namespace `manual-storage`, a PersistentVolumeClaim named `manual-pvc` requesting
  `1Gi` with `storageClassName` set to the **empty string** (so it does not use the
  default class).
- A pod named `manual-pod` in the same namespace using image `busybox:1.36`
  (command `sleep 3600`) mounting that PVC at `/data`.

The PVC must reach `Bound` and the pod must be Running.

---

## Question 3 — 10%

**Context:** `kubectl config use-context kubernetes-admin@kubernetes`

In namespace `stateful`:

- Create a StorageClass named `cold` with provisioner `rancher.io/local-path` and
  `volumeBindingMode: WaitForFirstConsumer`.
- Create a **headless** Service named `web-svc` (`clusterIP: None`) with selector `app=web`
  on port `80`.
- Create a StatefulSet named `web` with 3 replicas of `nginx`, `serviceName: web-svc`,
  and a `volumeClaimTemplate` named `www` requesting `1Gi` from StorageClass `cold`,
  mounted at `/usr/share/nginx/html`.

> Pods only reach Running if a local-path provisioner exists (`./bootstrap.sh`).
> Readiness is not marked — the specs are.

---

## Question 4 — 10%

**Context:** `kubectl config use-context kubernetes-admin@kubernetes`

In namespace `limits`:

- Create a LimitRange named `resource-limits` for **Container** type with:
  - default limits `cpu: 200m`, `memory: 256Mi`
  - default requests `cpu: 100m`, `memory: 128Mi`
  - max `cpu: 500m`, `memory: 512Mi`
- Create a ResourceQuota named `compute-quota` with hard limits `cpu=2`, `memory=2Gi`, `pods=5`.
- Create a Deployment named `test-limits`, 2 replicas of `nginx`, declaring **no** resources
  of its own so it inherits the LimitRange defaults.

---

## Question 5 — 8%

**Context:** `kubectl config use-context kubernetes-admin@kubernetes`

In namespace `consumer`, create a Deployment named `resource-consumer`, 3 replicas,
image `registry.k8s.io/e2e-test-images/resource-consumer:1.13`, with requests
`cpu: 100m` / `memory: 128Mi` and limits `cpu: 200m` / `memory: 256Mi`.

Add a HorizontalPodAutoscaler targeting **50%** CPU utilisation, min `3`, max `6`.

---

## Question 6 — 10%

**Context:** `kubectl config use-context kubernetes-admin@kubernetes`

Create two PriorityClasses, both with `globalDefault: false` and
`preemptionPolicy: PreemptLowerPriority`:

| Name | Value |
|---|---|
| `high-priority` | `1000` |
| `low-priority` | `100` |

Then in namespace `priority` create two nginx pods:

- `high-priority-pod` — label `priority=high`, priorityClassName `high-priority`
- `low-priority-pod` — label `priority=low`, priorityClassName `low-priority`

Each must use `podAntiAffinity` (`requiredDuringSchedulingIgnoredDuringExecution`,
topologyKey `kubernetes.io/hostname`) so it will **not** be scheduled onto the same
node as the other pod.

---

## Question 7 — 8%

**Context:** `kubectl config use-context kubernetes-admin@kubernetes`

In namespace `dns-config`:

- Create a Deployment named `dns-app`, 2 replicas of `nginx`, and a ClusterIP Service
  named `dns-svc` on port `80`.
- Create a pod named `dns-tester` using image `infoblox/dnstools` that runs `nslookup`
  against both `dns-svc` and `dns-svc.dns-config.svc.cluster.local`, writing the combined
  output to `/tmp/dns-test.txt` inside the container, then stays alive.

---

## Question 8 — 12%

**Context:** `kubectl config use-context kubernetes-admin@kubernetes`

Build a Kustomize tree at `/tmp/exam/kustomize/`:

- `base/` — a Deployment named `nginx` (image `nginx`, 2 replicas) plus a `kustomization.yaml`.
- `overlays/production/` — an overlay that:
  - sets replicas to `3`
  - adds the label `environment=production`
  - generates a ConfigMap named `web-content` from a file `index.html` containing HTML
  - targets namespace `kustomize`

Create the `kustomize` namespace and apply the production overlay with `kubectl apply -k`.

---

## Question 9 — 10%

**Context:** `kubectl config use-context kubernetes-admin@kubernetes`

Add the Bitnami Helm repository (`https://charts.bitnami.com/bitnami`) and install the
`nginx` chart as release `web-release` into namespace `helm-test` (create it), setting:

- `service.type=NodePort`
- `replicaCount=2`

> Chart pods may fail to pull images depending on Bitnami's current registry state.
> Only the repo, the release and its values are marked.

---

## Question 10 — 15%

**Context:** `kubectl config use-context kubernetes-admin@kubernetes`

Install the **standard** Gateway API CRDs, then in namespace `gateway`:

- Create Deployments `app1` and `app2` (1 replica of `nginx` each) and matching ClusterIP
  Services `app1-svc` and `app2-svc`, each on port `8080` targeting container port `80`.
- Create a Gateway named `main-gateway` with a single HTTP listener on port `80`.
- Create an HTTPRoute named `app-routes` attached to that Gateway which routes:
  - path prefix `/app1` → `app1-svc:8080`
  - path prefix `/app2` → `app2-svc:8080`

> There is no gateway controller in the playground, so the Gateway will never become
> `Programmed`. Only the resources and their specs are marked.

---

### When the hour is up

```bash
./set-03/grade.sh
```
