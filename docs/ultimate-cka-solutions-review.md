# Technical review — *Ultimate Certified Kubernetes Administrator: Solutions*

A verification pass over the KodeKloud "Ultimate CKA" solutions document: what it gets
wrong, what it does not cover, and how far it takes you toward passing.

The document itself is third-party paid course material and is **not** committed to this
repository. This file records the review only.

**Document reviewed:** 53 questions (52 unique), 6 sections, 170 screenshots, ~61k
characters of text. Cluster in the screenshots reports `v1.24.1+k3s1`.

| Section | Questions |
|---|---|
| Troubleshooting | 19 |
| Architecture, Install and Maintenance | 15 |
| Scheduling | 7 |
| Service Networking | 7 |
| Storage | 4 |
| Practical Exercise | 1 (+6 tasks with no solutions) |

---

## 1. Errors found

Ordered by how much damage they do if you learn them as written.

### 1.1 Wrong DNS names — Service Networking Q1 · HIGH

```
kubectl exec -i -t dnsutils -- nslookup <service-name>.<namespace>.cluster.local
kubectl exec -i -t dnsutils -- nslookup <pod_name>.local
```

Both are wrong.

- A Service's FQDN is `<service>.<namespace>.svc.cluster.local`. The `svc` label is
  missing, so the lookup fails.
- Pod DNS records are `<pod-ip-with-dashes>.<namespace>.pod.cluster.local`
  (e.g. `10-244-1-5.default.pod.cluster.local`). `<pod_name>.local` is not a
  Kubernetes DNS record at all.

This matters more than a typo: the task is the classic CKA "record the nslookup output
to a file" question, graded on file **content**. Following the document as written
records failed lookups.

**Corrected to:**
```
kubectl exec -i -t dnsutils -- nslookup <service-name>.<namespace>.svc.cluster.local
kubectl exec -i -t dnsutils -- nslookup <pod-ip-with-dashes>.<namespace>.pod.cluster.local
```

### 1.2 A grep that silently returns nothing — Architecture Q12 · HIGH

```
Kubectl logs logger-cka03-arch | grep ‘INFO|ERROR’ > /root/logger-cka03-arch-all
```

Three faults in one line:

1. `Kubectl` — capitalised, so the shell reports command not found.
2. Smart quotes `‘ ’` — not shell quotes.
3. **`grep 'INFO|ERROR'` without `-E`** — basic grep treats `|` as a literal character,
   so this searches for the string `INFO|ERROR` and matches nothing.

Fault 3 is the dangerous one: fix the first two and the command *runs cleanly* and
writes an **empty file**. Silent wrong answers are worse than errors.

**Corrected to:** `kubectl logs logger-cka03-arch | grep -E 'INFO|ERROR' > /root/logger-cka03-arch-all`

### 1.3 Scheduling attributed to the controller manager — Troubleshooting Q5 · HIGH (conceptual)

> "As scheduling the pod to a specific node is the responsibility of the Kubernetes
> controller manager…"

The **kube-scheduler** assigns Pods to nodes. The **kube-controller-manager** creates the
Pods in the first place (Deployment → ReplicaSet → Pod).

The *fix* in that question is right — the symptom was replicas never being created, which
is a controller-manager fault — but the stated reason is wrong. The document contradicts
itself at Troubleshooting Q19, where it correctly attributes scheduling to the scheduler.

This one is worth dwelling on because the whole point of the "control plane down"
family of questions is mapping a symptom to the right component:

| Symptom | Component |
|---|---|
| Deployment shows 0 replicas, no ReplicaSet created | kube-controller-manager |
| Pods created but stuck `Pending`, no node assigned | kube-scheduler |
| `kubectl` itself refuses to connect | kube-apiserver / etcd |

**Corrected to:** "Creating the Pods behind a Deployment is the responsibility of the
kube-controller-manager (the kube-scheduler only assigns already-created Pods to nodes)…"

### 1.4 `/etc/Kubernetes/manifests/` — 2 occurrences · MEDIUM

Linux paths are case-sensitive; the directory is `/etc/kubernetes/manifests/`. As
written, the path does not exist. Appears in Architecture Q4 (etcd backup) and
Troubleshooting Q5.

### 1.5 `K top nodes` / `K top pods -A` — 8 occurrences · LOW

Capital `K` is not the alias. Copy-pasted, every one of these fails.

---

## 2. Structural problems

- **Architecture Q5 and Q15 are the same question**, duplicated verbatim (decode
  `beta-sec-cka14-arch`). So there are 52 unique questions, not the "~55" the
  introduction claims.
- **The document is incomplete.** The final "Practical Exercise → Question 1"
  (`green-deployment-cka15-trb`) ends after the question text with no solution, and the
  file stops there.
- **The Practical Exercise section has no solutions at all** — six tasks are reproduced
  with their grading criteria and nothing else.
- **Solutions lean on screenshots.** 170 images carry most of the terminal output, so
  commands and their results are frequently not in copyable text. Fine for reading,
  useless for grepping or practising from.

---

## 3. Coverage against the current CKA — the real limitation

Measured against the 46 distinct topics exercised by this repository's lab set, the
document covers **21 of 46 (46%)**.

**Covered:** ConfigMap volumes · CoreDNS · CrashLoop debugging · DNS debugging ·
DaemonSets · Ingress · PV reuse · NetworkPolicy · NodePort/headless Services ·
Pod Security · probes · RBAC · resource allocation · rolling updates · scheduler repair ·
sidecars · static pods · StorageClasses · taints/tolerations · etcd backup · etcd repair

**Not covered anywhere in the document:**

| | | |
|---|---|---|
| Gateway API | Helm | Kustomize |
| kubeadm upgrade | CSR / kubeconfig | Cert renewal |
| HPA | PriorityClass | PodDisruptionBudget / drain |
| StatefulSet | Node affinity | Anti-affinity |
| LimitRange / ResourceQuota | ClusterRole aggregation | CRDs |
| **etcd restore** | CNI installation | kubelet troubleshooting |
| kubelet maxPods | Manual scheduling / Binding API | Default StorageClass |
| Manual PV + node affinity | `kubectl patch` | cri-dockerd / containerd |

Two of those gaps deserve singling out:

- **etcd *backup* is covered; etcd *restore* is not.** Restore is the harder half, the
  half with the order-of-operations trap (restore to a *new* data directory, then
  repoint the static pod), and the half that is actually asked.
- **Helm, Kustomize and Gateway API** were added to the CKA curriculum in the 2025
  revision. Their complete absence, together with the `v1.24` cluster in the
  screenshots, dates this document to an **older syllabus**.

---

## 4. So — will understanding it completely let you pass?

**No, not on its own — but it is a good half.**

**What it genuinely gives you.** Its 19 troubleshooting questions are the strongest part,
and Troubleshooting is 30% of the exam. The method it models is sound and worth
absorbing: check endpoints against pod labels, read events before logs, compare PVC
against PV field by field, check the static pod manifest when a control-plane component
misbehaves. That habit transfers to faults the document never shows you.

**Why it is not sufficient.**

1. **Coverage.** 46% of current topics. You could understand every word and still meet
   whole exam questions — Gateway API, Helm, Kustomize, a kubeadm upgrade, an etcd
   restore — that the document never mentions.
2. **Age.** A v1.24-era syllabus. The exam has moved.
3. **Reading is not doing.** The document shows finished answers. The exam tests recall
   and speed under a clock, with no solution text. Reading a solution creates a strong
   feeling of understanding that does not survive a blank terminal — the single most
   common way well-prepared candidates fail.
4. **Errors.** The five above are exactly the sort you would internalise silently,
   and §1.3 would actively mis-route your diagnosis on a control-plane question.

**How to use it well.** Read a question, close the document, solve it on a live cluster,
*then* compare. Use it for the troubleshooting method, not as a syllabus. Then cover the
25 uncovered topics elsewhere — the lab set in this repository was built around exactly
that gap, and `scripts/exam-mode.sh` weights papers to the current domain split.

---

## 5. Corrections applied

A corrected copy of the document was produced with 14 text fixes:

| Fix | Count |
|---|---|
| `/etc/Kubernetes/` → `/etc/kubernetes/` | 2 |
| `K top …` → `k top …` | 8 |
| `grep -E`, lowercase `kubectl`, straight quotes | 1 |
| Service FQDN: added missing `.svc` | 1 |
| Pod DNS record corrected | 1 |
| Scheduling vs pod-creation attribution rewritten | 1 |

Plus the earlier readability pass: all 53 questions promoted to Heading 2, an
auto-building table of contents added, and 91 command lines set in monospace with
shading.

Verified after editing: **zero original text lost** (794 → 796 paragraphs, the two
additions being the TOC block), all **170 images byte-identical**, and OOXML schema
validation passing against the original.

Not verified: page rendering. LibreOffice in the build container cannot load any `.docx`
(it fails on a three-line test file), so the result was checked structurally rather than
visually. Open it in Word before relying on the layout.
