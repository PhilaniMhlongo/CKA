# CKA Practice Exam — Set 1

**Duration: 60 minutes · 10 questions · 100 points · cut score 66%**

Domains covered: Workloads & Scheduling, Storage, Services & Networking,
Cluster Architecture (RBAC), Troubleshooting.

> Allowed reference: kubernetes.io/docs only.
> Create every namespace you need — none of them exist yet, except where `setup.sh` seeded them.
> The marker inspects live cluster state, not your YAML files.

---

## Question 1 — 5%

**Context:** `kubectl config use-context k8s`

Create the namespace `app-team1`.

In that namespace, create a pod named `nginx-pod` using image `nginx:1.19`
with the label `run=nginx-pod`.

---

## Question 2 — 8%

**Context:** `kubectl config use-context k8s`

In namespace `config`:

- Create a ConfigMap named `app-config` with a single key `APP_COLOR` set to `blue`.
- Create a pod named `config-pod` using the `nginx` image that mounts `app-config`
  **as a volume** at `/etc/config`.

The file `/etc/config/APP_COLOR` must be readable inside the container.

---

## Question 3 — 10%

**Context:** `kubectl config use-context k8s`

In namespace `storage-task`:

- Create a PersistentVolumeClaim named `data-pvc` that uses StorageClass `standard`,
  requests `2Gi`, and has access mode `ReadWriteOnce`.
- Create a pod named `data-pod` using the `nginx` image that mounts that PVC at
  `/usr/share/nginx/html`.

> The PVC may stay `Pending` if you did not run `bootstrap.sh`. That is expected and
> is not marked — the claim and pod **specs** are what is graded.

---

## Question 4 — 10%

**Context:** `kubectl config use-context k8s`

In namespace `web`:

- Create a Deployment named `web-app` with `3` replicas using image `nginx:1.19`.
- Expose it with a **NodePort** Service named `web-service` on port `80`,
  targeting container port `80`.

All three pods must be available and the Service must have endpoints.

---

## Question 5 — 10%

**Context:** `kubectl config use-context k8s`

In namespace `networking`, create a NetworkPolicy named `db-policy` that allows
**ingress** traffic to pods labelled `role=db` **only** from pods labelled
`role=frontend`, and only on **TCP port 3306**.

No other ingress may be permitted to `role=db` pods.

---

## Question 6 — 10%

**Context:** `kubectl config use-context k8s`

In namespace `rbac`:

- Create a ServiceAccount named `app-sa`.
- Create a Role named `pod-reader` allowing `get` and `list` on `pods`.
- Create a RoleBinding named `read-pods` binding that Role to that ServiceAccount.

The ServiceAccount must **not** gain any permission beyond those two verbs on pods.

---

## Question 7 — 12%

**Context:** `kubectl config use-context k8s`

In namespace `scaling`:

- Create a Deployment named `scaling-app` with `2` replicas using image `nginx`.
  Set resource **requests** to `cpu: 200m`, `memory: 256Mi` and **limits** to
  `cpu: 500m`, `memory: 512Mi`.
- Create a HorizontalPodAutoscaler for that Deployment targeting **70%** average CPU
  utilisation, with a minimum of `2` and a maximum of `5` replicas.

> The HPA will report `<unknown>` targets without metrics-server. Not marked.

---

## Question 8 — 12%

**Context:** `kubectl config use-context k8s`

Pick any node in the cluster (`kubectl get nodes`) and label it `disk=ssd`.

Then, in namespace `scheduling`, create a Deployment named `app-scheduling` with
`3` replicas using image `nginx`. The Deployment must use
`requiredDuringSchedulingIgnoredDuringExecution` **node affinity** so its pods only
schedule onto nodes carrying the label `disk=ssd`.

All 3 pods must end up Running.

---

## Question 9 — 12%

**Context:** `kubectl config use-context k8s`

In namespace `logging`, create a DaemonSet named `log-collector` using image
`busybox:1.36`.

- Container command: `while true; do echo collecting logs from $(hostname); sleep 60; done`
- Mount the **host path** `/var/log` as a volume named `host-logs` at `/host-logs`
  inside the container, **read-only**.
- The DaemonSet must tolerate **all** taints so it runs on every node, control plane included.

---

## Question 10 — 11%

**Context:** `kubectl config use-context k8s`

`setup.sh` has already deployed a broken Deployment named `failing-app` in namespace
`troubleshoot`. Its pods never become ready.

There are **three** defects. Diagnose and fix all of them so the Deployment reports
2 available replicas:

1. the container port is wrong,
2. the memory limit is far too low,
3. the liveness probe points at the wrong port.

The container must serve on the nginx default port, the memory limit must be `256Mi`,
and the liveness probe must target the corrected port.

---

### When the hour is up

```bash
./set-01/grade.sh
```
