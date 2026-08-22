# CKA Practice Exam — Set 2

**Duration: 60 minutes · 10 questions · 100 points · cut score 66%**

Domains covered: Workloads & Scheduling, Security (Pod Security Admission, RBAC),
Services & Networking (DNS, NetworkPolicy), Storage, Rollouts.

> Allowed reference: kubernetes.io/docs only.
> Create every namespace you need — none of them exist yet.
> The marker inspects live cluster state, not your YAML files.

---

## Question 1 — 6%

**Context:** `kubectl config use-context kubernetes-admin@kubernetes`

In namespace `monitoring`, create a pod named `resource-pod` using the `nginx` image with:

| | CPU | Memory |
|---|---|---|
| requests | `100m` | `128Mi` |
| limits | `200m` | `256Mi` |

---

## Question 2 — 8%

**Context:** `kubectl config use-context kubernetes-admin@kubernetes`

In namespace `probes`, create a pod named `health-check` using the `nginx` image with **both**:

- a **liveness** probe: HTTP GET `/` on port `80`, `initialDelaySeconds: 5`
- a **readiness** probe: HTTP GET `/` on port `80`, `initialDelaySeconds: 5`

The pod must reach Ready.

---

## Question 3 — 8%

**Context:** `kubectl config use-context kubernetes-admin@kubernetes`

- Create a StorageClass named `fast-storage` with provisioner `kubernetes.io/no-provisioner`.
- Create the namespace `storage`.
- In it, create a PersistentVolumeClaim named `data-pvc` that uses StorageClass
  `fast-storage`, requests `1Gi`, access mode `ReadWriteOnce`.

> `no-provisioner` means nothing binds the claim — `Pending` is the correct outcome
> and is not marked.

---

## Question 4 — 10%

**Context:** `kubectl config use-context kubernetes-admin@kubernetes`

In namespace `monitoring`, create a pod named `logger` with **two containers** sharing
an `emptyDir` volume mounted at `/var/log` in both:

- container `busybox` (image `busybox:1.36`) that appends a timestamped line to
  `/var/log/app.log` every 10 seconds, forever;
- container `fluentd` (image `fluentd:v1.16-1`) mounting the same volume at the same path.

---

## Question 5 — 12%

**Context:** `kubectl config use-context kubernetes-admin@kubernetes`

Pick any node (`kubectl get nodes`) and taint it:

```
special-workload=true:NoSchedule
```

Then, in namespace `scheduling`:

- Create a Deployment named `toleration-deploy`, 2 replicas, image `nginx`, with a
  **toleration** matching that taint exactly.
- Create a Deployment named `normal-deploy`, 2 replicas, image `nginx`, with **no** toleration.

`normal-deploy` pods must not land on the tainted node.

> On a single-node playground, taint `controlplane` and expect `normal-deploy` to stay
> Pending — the marker accounts for that.

---

## Question 6 — 10%

**Context:** `kubectl config use-context kubernetes-admin@kubernetes`

Create namespace `security` and label it so that Pod Security Admission **enforces**
the `restricted` standard.

Then create a pod named `secure-pod` in that namespace, image
`nginxinc/nginx-unprivileged:1.25`, that satisfies the restricted policy:

- `runAsNonRoot: true`
- `runAsUser: 1000`
- `seccompProfile.type: RuntimeDefault`
- `allowPrivilegeEscalation: false`
- all capabilities dropped (`drop: ["ALL"]`)

If the pod is rejected by admission, your security context is wrong.

---

## Question 7 — 12%

**Context:** `kubectl config use-context kubernetes-admin@kubernetes`

In namespace `cluster-admin`:

- Create a ServiceAccount named `app-admin`.
- Create a Role named `app-admin` granting:
  - `list`, `get`, `watch` on `pods`
  - `list`, `get`, `watch`, `update` on `deployments` (apps group)
  - `create`, `delete` on `configmaps`
- Create a RoleBinding named `app-admin` binding that Role to that ServiceAccount.
- Create a pod named `admin-pod` using image `busybox:1.36` with command `sleep 3600`,
  running **as the `app-admin` ServiceAccount**.

---

## Question 8 — 12%

**Context:** `kubectl config use-context kubernetes-admin@kubernetes`

In namespace `dns-debug`:

- Create a Deployment named `web-app`, 3 replicas, image `nginx`.
- Create a ClusterIP Service named `web-svc` on port `80` targeting that Deployment.
- Create a pod named `dns-test` using image `busybox:1.36` (command `sleep 3600`) with a
  custom `dnsConfig` adding the search domain `dns-debug.svc.cluster.local`.

From inside `dns-test`, both of these must resolve:

```
nslookup web-svc
nslookup web-svc.dns-debug.svc.cluster.local
```

---

## Question 9 — 12%

**Context:** `kubectl config use-context kubernetes-admin@kubernetes`

In namespace `network`, create three Deployments — `web`, `api`, `db` — each with
1 replica of `nginx` and each carrying the pod label `app=<its own name>`.

Then create three NetworkPolicies:

| Name | Effect |
|---|---|
| `web-policy` | `web` pods may **egress only** to `api` pods |
| `api-policy` | `api` pods accept **ingress from `web`** and may **egress to `db`** |
| `db-policy` | `db` pods accept **ingress only from `api`** |

---

## Question 10 — 10%

**Context:** `kubectl config use-context kubernetes-admin@kubernetes`

In namespace `upgrade`:

1. Create a Deployment named `app-v1`, 4 replicas, image `nginx:1.19`, with a
   RollingUpdate strategy of `maxUnavailable: 1` and `maxSurge: 1`.
2. Update the image to `nginx:1.20` and wait for the rollout to complete.
3. Save the rollout history to `/tmp/exam/rollout-history.txt`.
4. Roll back to the previous revision so the Deployment is serving `nginx:1.19` again.

---

### When the hour is up

```bash
./set-02/grade.sh
```
