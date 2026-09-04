# Ultimate CKA — Set 1, model answers

Read these *after* marking. Every command assumes the single Killercoda cluster.

---

## Q1 — Secret `secure-sec-cka12-arch`

```bash
kubectl create namespace secure-sys-cka12-arch
kubectl create secret generic secure-sec-cka12-arch \
  -n secure-sys-cka12-arch --from-literal=color=darkblue

# verify the way the marker does
kubectl get secret secure-sec-cka12-arch -n secure-sys-cka12-arch \
  -o jsonpath='{.data.color}' | base64 -d
```

`describe secret` shows only `color: 8 bytes` — it never prints the value. To see
it you must decode, which is the point of the question.

---

## Q2 — Looping pod

There is no imperative flag for a shell loop, so generate and edit:

```bash
kubectl run looper-cka16-arch --image=busybox --dry-run=client -o yaml \
  -- /bin/sh -c 'while true; do echo hello; sleep 10; done' > looper.yaml
kubectl apply -f looper.yaml
kubectl logs looper-cka16-arch
```

Everything after `--` becomes the container's args. Without the loop the container
exits immediately and the pod enters CrashLoopBackOff.

---

## Q3 — Adding a sidecar

Pod container specs are immutable, so this is a get-edit-recreate:

```bash
kubectl get pod elastic-app-cka02-arch -o yaml > elastic.yaml
```

Add a second container that mounts the **same** volume:

```yaml
  - name: sidecar
    image: busybox
    command: ["sh","-c","tail -f /var/log/elastic-app.log"]
    volumeMounts:
    - name: log-volume
      mountPath: /var/log
```

Strip `status:`, `metadata.uid`, `resourceVersion` and `creationTimestamp` from the
dump, then:

```bash
kubectl delete pod elastic-app-cka02-arch --force --grace-period=0
kubectl apply -f elastic.yaml
kubectl logs elastic-app-cka02-arch -c sidecar
```

The mount is the whole question: without it the sidecar tails a path that does not
exist in its own filesystem and crash-loops.

Prefer `tail -F` over `tail -f` in real life — capital F re-opens the file after
rotation. The original task text specifies lowercase, and both satisfy the marker.

---

## Q4 — Two containers, one emptyDir

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: grape-pod-cka06-str
  namespace: grape-cka06-str
spec:
  volumes:
  - name: grape-vol-cka06-str
    emptyDir: {}
  containers:
  - name: main
    image: nginx
    volumeMounts:
    - { name: grape-vol-cka06-str, mountPath: /var/log/nginx }
  - name: sidecar
    image: busybox
    command: ["sh","-c","sleep 3600"]
    volumeMounts:
    - { name: grape-vol-cka06-str, mountPath: /usr/src }
```

busybox with no command exits straight away, so the sleep is required to keep the
pod Running.

---

## Q5 — DNS lookups to file

```bash
kubectl run nginx-resolver-cka06-svcn --image=nginx
kubectl expose pod nginx-resolver-cka06-svcn \
  --name=nginx-resolver-service-cka06-svcn --port=80 --target-port=80

mkdir -p /root/CKA

# service record: <service>.<namespace>.svc.cluster.local
kubectl run dnsutils --image=busybox:1.28 --restart=Never --rm -it -- \
  nslookup nginx-resolver-service-cka06-svcn.default.svc.cluster.local \
  > /root/CKA/nginx.svc.cka06.svcn

# pod record: the POD IP with dots replaced by dashes
IP=$(kubectl get pod nginx-resolver-cka06-svcn -o jsonpath='{.status.podIP}' | tr '.' '-')
kubectl run dnsutils --image=busybox:1.28 --restart=Never --rm -it -- \
  nslookup ${IP}.default.pod.cluster.local \
  > /root/CKA/nginx.pod.cka06.svcn
```

**This is the question the original document gets wrong.** It omits `svc` from the
service FQDN and gives `<pod_name>.local` for the pod record. Pods have no DNS
record under their name — the record is built from the IP.

---

## Q6 — LoadBalancer service

```bash
kubectl expose deployment webapp-wear-cka09-svcn -n app-space \
  --name=wear-service-cka09-svcn --type=LoadBalancer --port=8080 --target-port=80

kubectl get endpoints wear-service-cka09-svcn -n app-space   # expect 2 addresses
```

`EXTERNAL-IP` stays `<pending>` without a cloud provider. That is correct
behaviour, not a fault — the marker checks the type and the endpoints instead.

---

## Q7 — Reading effective permissions

```bash
kubectl describe clusterrole red-role-cka23-arch
```

It grants `get`, `list`, `watch` on `deployments`. Then:

```bash
echo "resource:deployments|verbs:get,list,watch" > /opt/red-sa-cka23-arch
```

Cross-check with the identity itself rather than trusting the role name:

```bash
SA=system:serviceaccount:default:red-sa-cka23-arch
kubectl auth can-i list deployments --as=$SA     # yes
kubectl auth can-i delete deployments --as=$SA   # no
kubectl auth can-i --list --as=$SA
```

---

## Q8 — Template that will not apply

```bash
kubectl apply -f /root/app-cka07-trb.yaml
# error: namespaces "app-cka07-trb" not found
```

The manifest targets a namespace that does not exist, and you were told not to edit
the file — so create the namespace instead:

```bash
kubectl create namespace app-cka07-trb
kubectl apply -f /root/app-cka07-trb.yaml
kubectl rollout status deploy/app-cka07-trb -n app-cka07-trb
```

---

## Q9 — Taint and toleration

```bash
kubectl describe pod yello-cka20-trb -n yello-cka20-trb | grep -A5 Events
kubectl describe node <node> | grep -i taint
#   app-type=yello:NoSchedule
kubectl get pod yello-cka20-trb -n yello-cka20-trb -o yaml | grep -A5 tolerations
#   value: blue      <- does not match
```

The toleration value is wrong. Pod specs are immutable, so recreate it with
`value: "yello"`, leaving the node taint alone:

```bash
kubectl get pod yello-cka20-trb -n yello-cka20-trb -o yaml > yello.yaml
sed -i 's/value: "blue"/value: "yello"/' yello.yaml
kubectl delete pod yello-cka20-trb -n yello-cka20-trb --force --grace-period=0
kubectl apply -f yello.yaml
```

A toleration is permission to land on a tainted node, not a request to. The
`nodeSelector` is what actually sends it there.

---

## Q10 — Two faults in one deployment

**Fault 1 — the PVC cannot bind.** It asks for 150Mi from a 100Mi PV:

```bash
kubectl get pvc -n web-cka17-trb        # Pending
kubectl get pv web-pv-cka17-trb         # 100Mi
```

PVC spec fields are immutable, so delete and recreate at 100Mi. The pod holds the
claim, so scale the deployment down first or the delete will hang on
`pvc-protection`:

```bash
kubectl scale deploy web-dp-cka17-trb -n web-cka17-trb --replicas=0
kubectl delete pvc web-pvc-cka17-trb -n web-cka17-trb
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata: { name: web-pvc-cka17-trb, namespace: web-cka17-trb }
spec:
  storageClassName: web-cka17-trb
  accessModes: ["ReadWriteOnce"]
  resources: { requests: { storage: 100Mi } }
EOF
```

**Fault 2 — the command.** `/bin/bsh` does not exist:

```bash
kubectl edit deploy web-dp-cka17-trb -n web-cka17-trb   # /bin/bsh -> /bin/sh
kubectl scale deploy web-dp-cka17-trb -n web-cka17-trb --replicas=1
kubectl rollout status deploy/web-dp-cka17-trb -n web-cka17-trb
```

Order matters: fix the claim first, because the pod cannot schedule at all while
the PVC is Pending, so you would never see the second fault.
