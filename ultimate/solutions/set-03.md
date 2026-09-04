# Ultimate CKA — Set 3, model answers

---

## Q1 — ocean-tv-wl09

`maxSurge`/`maxUnavailable` have no imperative flag, so generate and edit:

```bash
kubectl create deployment ocean-tv-wl09 --image=kodekloud/webapp-color:v1 \
  --replicas=3 --dry-run=client -o yaml > ocean.yaml
```

Add under `spec:` (a sibling of `replicas`):

```yaml
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 40%
      maxSurge: 55%
```

```bash
kubectl apply -f ocean.yaml
kubectl rollout status deploy/ocean-tv-wl09

# container name comes from the image - confirm before set image
kubectl get deploy ocean-tv-wl09 -o jsonpath='{.spec.template.spec.containers[0].name}'
kubectl set image deploy/ocean-tv-wl09 webapp-color=kodekloud/webapp-color:v2
kubectl rollout status deploy/ocean-tv-wl09

kubectl rollout history deploy/ocean-tv-wl09
kubectl rollout history deploy/ocean-tv-wl09 --no-headers | wc -l > /opt/revision-count.txt

kubectl rollout undo deploy/ocean-tv-wl09
kubectl rollout status deploy/ocean-tv-wl09
```

The question asks for the revision **count**, not the history listing. Percentages
must be quoted in YAML if you hand-write them.

---

## Q2 — Redis pod and service

```bash
kubectl run messaging-cka07-svcn -n msg-cka07 --image=redis:alpine --labels=tier=msg
kubectl expose pod messaging-cka07-svcn -n msg-cka07 \
  --name=messaging-service-cka07-svcn --port=6379 --target-port=6379

kubectl get endpoints messaging-service-cka07-svcn -n msg-cka07
```

`kubectl expose` copies the pod's labels into the selector, so the labels must exist
**when the pod is created**. Adding them later leaves the service selecting nothing.

---

## Q3 — NodePort on a specific port

```bash
kubectl create deployment hr-web-app-cka08-svcn -n hr-cka08 \
  --image=kodekloud/webapp-color --replicas=2

kubectl expose deployment hr-web-app-cka08-svcn -n hr-cka08 \
  --name=hr-web-app-service-cka08-svcn --type=NodePort --port=8080 --target-port=8080

kubectl patch svc hr-web-app-service-cka08-svcn -n hr-cka08 \
  -p '{"spec":{"ports":[{"port":8080,"targetPort":8080,"nodePort":30082}]}}'

kubectl get svc,endpoints -n hr-cka08
```

`kubectl expose` cannot be asked for a specific `nodePort`, which is why this is two
steps. Wait for both pods before checking endpoints.

---

## Q4 — PVC added to an existing manifest

```bash
kubectl get pv peach-pv-cka05-str    # 150Mi, RWO, class peach-manual
```

Append the claim and the mount to `/root/peach-pod-cka05-str.yaml`:

```yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: peach-pvc-cka05-str
spec:
  storageClassName: peach-manual
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 100Mi
```

and in the pod spec:

```yaml
  volumes:
  - name: peach-vol
    persistentVolumeClaim:
      claimName: peach-pvc-cka05-str
  containers:
  - name: web
    image: nginx:1.25
    volumeMounts:
    - name: peach-vol
      mountPath: /var/www/html
```

```bash
kubectl apply -f /root/peach-pod-cka05-str.yaml
kubectl get pvc peach-pvc-cka05-str    # Bound
```

The `storageClassName` must be copied from the PV. Omit it and the claim goes to the
default class instead and never binds to this volume.

---

## Q5 — Gi where Mi was meant

```bash
kubectl describe pod nginx-wl06 -n wl06-cka | grep -A5 Events
#   0/2 nodes are available: Insufficient memory
```

Pod resources are immutable, so recreate:

```bash
kubectl get pod nginx-wl06 -n wl06-cka -o yaml > wl06.yaml
sed -i 's/50Gi/50Mi/; s/100Gi/100Mi/' wl06.yaml
kubectl delete pod nginx-wl06 -n wl06-cka --force --grace-period=0
kubectl apply -f wl06.yaml
```

Only **requests** drive scheduling. A pod asking for 50Gi on a node with a few GB
can never be placed, whatever the limit says.

---

## Q6 — Requests above limits

```bash
kubectl apply -f /root/app-wl03.yaml
#   Invalid value: must be less than or equal to memory limit
```

Limits must not change, so lower the requests to fit inside them:

```yaml
      requests:
        memory: "50Mi"
        cpu: "100m"
      limits:
        memory: "100Mi"
        cpu: "200m"
```

```bash
kubectl apply -f /root/app-wl03.yaml
```

A request may equal the limit but never exceed it. When a task freezes the limits,
the requests are the side you move.

---

## Q7 — A probe that kills a healthy container

```bash
kubectl apply -f /root/red-probe-cka12-trb.yaml
kubectl describe pod red-probe-cka12-trb -n trb-cka12 | grep -A10 Events
#   Liveness probe failed: connection refused
```

The container is a busybox shell — it serves no HTTP, so an `httpGet` probe can
never succeed and the kubelet restarts it forever. The `args` may not change, so fix
the probe to match what the container actually does:

```yaml
    livenessProbe:
      exec:
        command: ["sh","-c","test -f /tmp/ready"]
      initialDelaySeconds: 5
      periodSeconds: 10
```

Then recreate the pod and watch it for a minute:

```bash
kubectl delete pod red-probe-cka12-trb -n trb-cka12 --force --grace-period=0
kubectl apply -f /root/red-probe-cka12-trb.yaml
kubectl get pod red-probe-cka12-trb -n trb-cka12 -w
```

Match the probe to the workload: `httpGet` for HTTP servers, `exec` for anything
else, `tcpSocket` when a port is open but speaks no HTTP. And `initialDelaySeconds`
must exceed the app's startup time, or a healthy app restarts forever.

---

## Q8 — A secret key that does not exist

```bash
kubectl get pods -n db-cka05-trb            # CreateContainerConfigError
kubectl describe pod <pod> -n db-cka05-trb | tail -20
#   couldn't find key DB_Passwd in Secret db-cka05-trb/db-secret-cka05-trb
```

`CreateContainerConfigError` is not a crash — the kubelet cannot build the container
at all. Compare what the secret holds against what the deployment asks for:

```bash
kubectl get secret db-secret-cka05-trb -n db-cka05-trb -o jsonpath='{.data}'
#   DB_User, DB_Password
```

The deployment references `DB_Passwd`. Fix the reference — not the secret, and
without dropping any DB variable:

```bash
kubectl edit deploy db-deployment-cka05-trb -n db-cka05-trb    # DB_Passwd -> DB_Password
kubectl rollout status deploy/db-deployment-cka05-trb -n db-cka05-trb
```

No pod delete is needed: fix the reference and the kubelet retries by itself.

---

## Q9 — Two faults in one deployment

```bash
kubectl get pods -n blue-cka09-trb
kubectl describe pod <pod> -n blue-cka09-trb | tail -25
```

1. **`command: ["/bin/sh", "nginx -g 'daemon off;'"]`** — without `-c`, the shell
   treats the whole string as a filename to run. Must be
   `["/bin/sh","-c","nginx -g 'daemon off;'"]`.
2. **The ConfigMap is mounted over `/etc/nginx/nginx.conf` as a directory**, which
   replaces the file with a folder. Mount a single key with `subPath`:

```yaml
        volumeMounts:
        - name: conf
          mountPath: /etc/nginx/nginx.conf
          subPath: nginx.conf
```

```bash
kubectl edit deploy blue-dp-cka09-trb -n blue-cka09-trb
kubectl rollout status deploy/blue-dp-cka09-trb -n blue-cka09-trb
```

`subPath` is the difference between mounting a *file* and burying a directory on top
of one — a classic and easy mark to lose.

---

## Q10 — etcd snapshot

Never memorise the paths; read them off the static pod manifest:

```bash
grep -E "listen-client-urls|trusted-ca-file|cert-file|key-file|data-dir" \
  /etc/kubernetes/manifests/etcd.yaml
```

```bash
export ETCDCTL_API=3
etcdctl snapshot save /opt/cluster1_backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

etcdctl snapshot status /opt/cluster1_backup.db --write-out=table \
  | tee /opt/etcd-snapshot-status.txt
```

`snapshot status` reads the **file**, so it needs no certificates — only `snapshot
save` talks to the server. On newer clusters `snapshot status` has moved to
`etcdutl`; if etcdctl refuses, run the same arguments through `etcdutl`.

If `etcdctl` is missing entirely: `apt-get install -y etcd-client`.
