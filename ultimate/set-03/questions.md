# Ultimate CKA — Set 3

**60 minutes · 10 questions · 100 points · cut score 66%**

The hardest of the three. Includes the Practical Exercise tasks that the original
document lists but never answers, plus its multi-fault troubleshooting questions.

> Allowed reference: kubernetes.io/docs only.
> `setup.sh` has seeded what these questions expect, faults included.
> Question 10 touches the control plane — leave it until last.

---

## Question 1 — 12%

In the `default` namespace, create a deployment `ocean-tv-wl09` using image
`kodekloud/webapp-color:v1` with:

1. 3 replicas
2. `maxUnavailable` 40% and `maxSurge` 55%

Then:

3. wait for all pods to be ready
4. upgrade the image to `kodekloud/webapp-color:v2` and watch the rollout
5. write the **number of revisions** in the rollout history to `/opt/revision-count.txt`
6. roll back to the previous image

---

## Question 2 — 6%

Create a pod `messaging-cka07-svcn` in namespace `msg-cka07` using image
`redis:alpine` with the label `tier=msg`.

Expose it inside the cluster with a service `messaging-service-cka07-svcn` on
port `6379`.

---

## Question 3 — 8%

In namespace `hr-cka08`, create a deployment `hr-web-app-cka08-svcn` using image
`kodekloud/webapp-color` with 2 replicas.

Expose it as a **NodePort** service `hr-web-app-service-cka08-svcn` on node port
`30082`. The application listens on port `8080`.

---

## Question 4 — 10%

A pod definition exists at `/root/peach-pod-cka05-str.yaml`, and a
PersistentVolume `peach-pv-cka05-str` already exists.

Update that manifest so it also creates a PersistentVolumeClaim
`peach-pvc-cka05-str` claiming **100Mi** with access mode `ReadWriteOnce`, and so
the pod mounts the claim at `/var/www/html`.

Apply it. The PVC must be `Bound` and the pod `Running`.

---

## Question 5 — 8%

The pod `nginx-wl06` in namespace `wl06-cka` is stuck `Pending`. Whoever wrote it
used gibibytes where they meant mebibytes, so the node cannot satisfy the request.

Fix the units and get the pod Running. You may delete and recreate the pod.

---

## Question 6 — 8%

A manifest at `/root/app-wl03.yaml` will not create its pod.

Fix the manifest and deploy it so the pod runs.

**The existing resource limits must not change.**

---

## Question 7 — 12%

A pod template is stored at `/root/red-probe-cka12-trb.yaml`. Applying it as-is
produces a pod that keeps restarting.

Fix the template and create the pod in namespace `trb-cka12`. Watch it for a
minute — it must be stable, not restarting.

**Do not change the `args:` section.**

---

## Question 8 — 12%

The deployment `db-deployment-cka05-trb` in namespace `db-cka05-trb` has 0 of 1
pods ready.

Fix it. **Do not remove any DB-related environment variable** from the
deployment.

---

## Question 9 — 12%

The deployment `blue-dp-cka09-trb` in namespace `blue-cka09-trb` has 0 of 1 pods
running. There are two distinct faults.

Fix both so the pod runs.

---

## Question 10 — 12%

**Do this one last — it touches etcd.**

Take a snapshot of this cluster's etcd and save it to `/opt/cluster1_backup.db`.

Then write the snapshot's status output to `/opt/etcd-snapshot-status.txt`.

You must find the endpoint and the certificate paths yourself; the etcd static pod
manifest tells you where they are.
