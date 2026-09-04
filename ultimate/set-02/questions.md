# Ultimate CKA — Set 2

**60 minutes · 10 questions · 100 points · cut score 66%**

Adapted from the KodeKloud Ultimate CKA mock exam for a single Killercoda cluster.
Object names match the original document. Disjoint from Set 1 — no question repeats.

> Allowed reference: kubernetes.io/docs only.
> `setup.sh` has seeded what these questions expect, faults included.
> Do not delete the objects you were asked to fix.

---

## Question 1 — 10%

Create a ServiceAccount `deploy-cka20-arch` in the `default` namespace.

Create a ClusterRole `deploy-role-cka20-arch` that allows **only** `get` on
`deployments`.

Bind them with a ClusterRoleBinding named `deploy-role-binding-cka20-arch`.

Verify with `kubectl auth can-i` that the ServiceAccount can get deployments in
the `default` namespace, and cannot delete them.

---

## Question 2 — 8%

The file `/opt/db-user-pass` exists on this node.

Create a generic secret named `db-user-pass-cka17-arch` in the `default`
namespace from the **contents of that file**.

---

## Question 3 — 8%

A PersistentVolume `apple-pv-cka04-str` already exists.

Create a PersistentVolumeClaim named `apple-pvc-cka04-str` in the `default`
namespace that requests **40Mi** from it, with access mode `ReadWriteOnce` and
storage class `manual`.

The claim must end up `Bound`.

---

## Question 4 — 8%

Create a StorageClass named `banana-sc-cka08-str` with:

- provisioner `kubernetes.io/no-provisioner`
- volume binding mode `WaitForFirstConsumer`
- volume expansion enabled

---

## Question 5 — 12%

In namespace `svcn-cka05`, two pods exist: `pod-23` and `pod-21`.

**Part 1.** Create a single ClusterIP service named `service-3421-svcn` in that
namespace that has **both** pods as endpoints, with `port: 8080` and
`targetPort: 80`.

**Part 2.** Write the pod names and IPs of every pod in every namespace to
`/root/pod_ips_cka05_svcn`, sorted by IP, with these column headings:

```
POD_NAME   IP_ADDR
```

---

## Question 6 — 10%

A deployment `nginx-deployment-cka04-svcn` and a service
`nginx-service-cka04-svcn` exist in namespace `svcn-cka04`.

Create an Ingress named `nginx-ingress-cka04-svcn` in the same namespace that
routes to that service, with:

- `pathType: Prefix`
- `path: /`
- backend service port `80`
- the annotation `nginx.ingress.kubernetes.io/ssl-redirect: "false"`

---

## Question 7 — 12%

A ServiceAccount `thor-cka24-trb` in namespace `trb-cka24` should be able to
`get` and `list` **pods and secrets** in that namespace. It currently cannot.

A Role and RoleBinding already exist. Find and fix every mistake in them.

The ServiceAccount must not gain any other permission — in particular it must not
be able to delete anything.

---

## Question 8 — 16%

The deployment `web-dp-cka06-trb` in namespace `web-cka06-trb` is meant to be
reachable through the service `web-service-cka06-trb`, but it is not working.

There is more than one fault. Fix them all so the service has healthy endpoints
and the pod is Running.

---

## Question 9 — 10%

In namespace `cyan-ns-cka28-trb`, the pod `cyan-pod-cka28-trb` (label
`app=cyan`) is exposed by service `cyan-svc-cka28-trb` on port 80.

A NetworkPolicy `cyan-np-cka28-trb` in that namespace is supposed to allow
traffic **only** from pods labelled `app=cyan-white` in the `default` namespace.
Right now nothing can reach the pod at all.

Fix the NetworkPolicy so `cyan-white-cka28-trb1` (in `default`) can reach it on
port 80, while `cyan-black-cka28-trb` (also in `default`) still cannot.

**Do not delete the NetworkPolicy.**

---

## Question 10 — 6%

The deployment `app-wl07` in namespace `dev-wl07` was rolled forward to a broken
image and its pods will not start.

Roll it back to the previous working revision, then:

- write the image now in use to `/root/rolling-back-record.txt`
- scale the deployment to 5 replicas
