# Ultimate CKA — Set 2, model answers

---

## Q1 — SA + ClusterRole + ClusterRoleBinding

```bash
kubectl create serviceaccount deploy-cka20-arch
kubectl create clusterrole deploy-role-cka20-arch --verb=get --resource=deployments
kubectl create clusterrolebinding deploy-role-binding-cka20-arch \
  --clusterrole=deploy-role-cka20-arch \
  --serviceaccount=default:deploy-cka20-arch

SA=system:serviceaccount:default:deploy-cka20-arch
kubectl auth can-i get deployments    --as=$SA   # yes
kubectl auth can-i delete deployments --as=$SA   # no
```

The `--as=` format is `system:serviceaccount:<namespace>:<name>`. Getting that
wrong makes every check return `no` and sends you hunting a non-existent RBAC bug.

---

## Q2 — Secret from a file

```bash
kubectl create secret generic db-user-pass-cka17-arch --from-file=/opt/db-user-pass
```

`--from-file` uses the **filename** as the key and the whole file as the value.
`--from-env-file` instead parses `key=value` lines into separate keys. Either
satisfies this question; know the difference, because a task that names the keys
requires the second.

---

## Q3 — PVC that binds

```bash
kubectl get pv apple-pv-cka04-str    # 50Mi, RWO, class manual
```

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: apple-pvc-cka04-str
spec:
  storageClassName: manual
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 40Mi
```

Binding needs the class to match exactly, the access mode to be satisfied, and the
PV to be **at least** as large as the request. 40Mi from a 50Mi PV binds and wastes
10Mi — that is normal.

---

## Q4 — StorageClass

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: banana-sc-cka08-str
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
```

`provisioner`, `volumeBindingMode` and `allowVolumeExpansion` are top-level fields,
not under `spec:` — StorageClass has no `spec`. This is the most common mistake on
this question.

---

## Q5 — One service, two pods

```bash
kubectl get pods -n svcn-cka05 --show-labels
```

`pod-23` and `pod-21` share `tier=backend`; the decoy `pod-99` is `tier=frontend`.
A service selects on labels, so select the label they share and nothing else:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: service-3421-svcn
  namespace: svcn-cka05
spec:
  selector:
    tier: backend
  ports:
  - port: 8080
    targetPort: 80
```

```bash
kubectl get endpoints service-3421-svcn -n svcn-cka05    # exactly 2 addresses
```

Part 2:

```bash
kubectl get pods -A \
  -o=custom-columns='POD_NAME:metadata.name,IP_ADDR:status.podIP' \
  --sort-by=.status.podIP > /root/pod_ips_cka05_svcn
```

---

## Q6 — Ingress

```bash
kubectl create ingress nginx-ingress-cka04-svcn -n svcn-cka04 \
  --rule="/*=nginx-service-cka04-svcn:80" \
  --annotation nginx.ingress.kubernetes.io/ssl-redirect=false \
  --dry-run=client -o yaml > ing.yaml
```

Check `pathType` in the generated file: `--rule="/*=..."` yields `Prefix`, while
`--rule="/=..."` yields `Exact`. The question asks for `Prefix` with path `/`, so
set both explicitly if the generator disagrees, then `kubectl apply -f ing.yaml`.

---

## Q7 — Three RBAC faults

```bash
kubectl get role thor-role-cka24-trb -n trb-cka24 -o yaml
kubectl get rolebinding thor-role-binding-cka24-trb -n trb-cka24 -o yaml
```

1. **Singular resources** — `["pod","secret"]` matches nothing. Must be `["pods","secrets"]`.
2. **Wrong verb** — `["delete"]` instead of `["get","list"]`.
3. **Wrong subject namespace** — the binding names the ServiceAccount in `default`,
   but it lives in `trb-cka24`. A ServiceAccount subject carries its own
   `namespace:` field; it does not inherit the binding's.

```bash
kubectl edit role thor-role-cka24-trb -n trb-cka24
kubectl edit rolebinding thor-role-binding-cka24-trb -n trb-cka24

SA=system:serviceaccount:trb-cka24:thor-cka24-trb
kubectl auth can-i list secrets --as=$SA -n trb-cka24   # yes
kubectl auth can-i delete pods  --as=$SA -n trb-cka24   # no
```

All three fail silently and identically — every request is denied — so you have to
read the objects rather than guess from the symptom.

---

## Q8 — Three faults between deployment and service

Work outward from the pod:

```bash
kubectl get pods -n web-cka06-trb                       # ImagePullBackOff
kubectl get endpoints web-service-cka06-trb -n web-cka06-trb   # <none>
```

1. **Image `httpd:latest-fake` does not exist** — set a real one:
   `kubectl set image deploy/web-dp-cka06-trb web=httpd:latest -n web-cka06-trb`
2. **Service selector `app: webcka06`** does not match the pods' `app: web-cka06`.
3. **`targetPort: 8080`** but httpd listens on 80.

```bash
kubectl patch svc web-service-cka06-trb -n web-cka06-trb --type=json -p='[
  {"op":"replace","path":"/spec/selector/app","value":"web-cka06"},
  {"op":"replace","path":"/spec/ports/0/targetPort","value":80}]'

kubectl get endpoints web-service-cka06-trb -n web-cka06-trb
```

Endpoints is the fork in the road: empty means selector or readiness; populated but
not responding means the port or the app.

---

## Q9 — NetworkPolicy with two faults

```bash
kubectl get networkpolicy cyan-np-cka28-trb -n cyan-ns-cka28-trb -o yaml
```

1. **Port 8080** — the pod serves on 80.
2. **A bare `podSelector`** in the `from:` block only matches pods in the
   policy's **own** namespace. The client lives in `default`, so a
   `namespaceSelector` is required.

```yaml
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: default
      podSelector:
        matchLabels:
          app: cyan-white
    ports:
    - protocol: TCP
      port: 80
```

The two selectors sit under **one** dash, so they are ANDed: pods labelled
`app=cyan-white` *in* the `default` namespace. Two dashes would mean OR — every pod
in `default` plus every `cyan-white` pod anywhere — and the black pod would get in,
failing the negative check.

```bash
kubectl exec cyan-white-cka28-trb1 -- wget -qO- --timeout=5 \
  http://cyan-svc-cka28-trb.cyan-ns-cka28-trb:80     # works
kubectl exec cyan-black-cka28-trb  -- wget -qO- --timeout=5 \
  http://cyan-svc-cka28-trb.cyan-ns-cka28-trb:80     # times out
```

---

## Q10 — Rollback, record, scale

```bash
kubectl rollout history deploy/app-wl07 -n dev-wl07
kubectl rollout undo deploy/app-wl07 -n dev-wl07
kubectl rollout status deploy/app-wl07 -n dev-wl07

kubectl get deploy app-wl07 -n dev-wl07 \
  -o jsonpath='{.spec.template.spec.containers[0].image}' > /root/rolling-back-record.txt

kubectl scale deploy app-wl07 -n dev-wl07 --replicas=5
```

Record the image **after** the rollback — that is what "the image currently in use"
means, and doing it first is the usual way to lose this mark.
