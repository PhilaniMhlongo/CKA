# Ultimate CKA — Set 1

**60 minutes · 10 questions · 100 points · cut score 66%**

Adapted from the KodeKloud Ultimate CKA mock exam for a **single Killercoda
cluster**. The original runs on four clusters with a student-node; here everything
happens on `controlplane` (plus `node01`), so the "set the context to clusterN"
preamble is dropped. Object names are kept identical to the original so the two
line up question for question.

> Allowed reference: kubernetes.io/docs only.
> `setup.sh` has already seeded the resources some questions expect — including
> the deliberately broken ones. Do not delete what you were asked to fix.
> The marker inspects live cluster state, not your YAML files.

---

## Question 1 — 6%

Create a generic secret called `secure-sec-cka12-arch` in the
`secure-sys-cka12-arch` namespace, holding the key/value `color=darkblue`.

Create the namespace if it does not exist.

---

## Question 2 — 8%

Run a pod called `looper-cka16-arch` in the `default` namespace using the
`busybox` image, running this loop:

```
while true; do echo hello; sleep 10; done
```

The pod must stay running and print `hello` every 10 seconds.

---

## Question 3 — 10%

A pod called `elastic-app-cka02-arch` is running in the `default` namespace. Its
single application container writes logs to `/var/log/elastic-app.log`.

A logging agent needs those logs on stdout, but the main container must not take
on extra read load. Recreate this pod with an **additional sidecar container**
named `sidecar`, using the `busybox` image, running:

```
tail -f /var/log/elastic-app.log
```

Both containers must share the log directory, and the pod must end up Running
with 2/2 containers ready.

---

## Question 4 — 10%

In namespace `grape-cka06-str`, create a pod named `grape-pod-cka06-str` with two
containers sharing one volume:

- main container: image `nginx`, mounts volume `grape-vol-cka06-str` at `/var/log/nginx`
- sidecar container: image `busybox`, kept alive with a sleep command, mounts the
  **same** volume at `/usr/src`
- the volume is of type `emptyDir`

---

## Question 5 — 12%

Create a pod `nginx-resolver-cka06-svcn` using image `nginx` in the `default`
namespace, and expose it internally with a service called
`nginx-resolver-service-cka06-svcn`.

Then, using a `busybox:1.28` pod for the lookups, record:

- the **service** DNS lookup in `/root/CKA/nginx.svc.cka06.svcn`
- the **pod** DNS lookup in `/root/CKA/nginx.pod.cka06.svcn`

Remember the two record shapes differ:

```
<service>.<namespace>.svc.cluster.local
<pod-ip-with-dashes>.<namespace>.pod.cluster.local
```

---

## Question 6 — 8%

A deployment `webapp-wear-cka09-svcn` is running in the `app-space` namespace.

Expose it with a service named `wear-service-cka09-svcn` of type `LoadBalancer`
on port 8080.

> On a bare-metal playground the EXTERNAL-IP stays `<pending>`. That is expected
> and is not marked.

---

## Question 7 — 8%

A ServiceAccount `red-sa-cka23-arch`, a ClusterRole `red-role-cka23-arch` and a
ClusterRoleBinding `red-role-binding-cka23-arch` already exist.

Work out what permissions that ServiceAccount actually has, and write the answer
to `/opt/red-sa-cka23-arch` in exactly this format:

```
resource:pods|verbs:get,list
```

(substituting the real resource and the real verbs, verbs comma-separated in the
order they appear in the role).

---

## Question 8 — 8%

A deployment template is stored at `/root/app-cka07-trb.yaml`. Creating it fails.

Find the cause, fix it, and get the deployment running.

**Do not modify the template file.**

---

## Question 9 — 12%

The pod `yello-cka20-trb` in namespace `yello-cka20-trb` is stuck `Pending`.

Fix it so the pod runs. You may recreate the pod.

**Do not remove or change any taint on the cluster nodes.**

---

## Question 10 — 18%

The deployment `web-dp-cka17-trb` in namespace `web-cka17-trb` has 0 of 1 pods
running. There is more than one fault.

Get the pod Running and stable — not restarting. The application listens on port
80 inside the container.
