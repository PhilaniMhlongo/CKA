# Ultimate CKA — practice sets for Killercoda

Three timed 60-minute papers built from the questions in the KodeKloud *Ultimate
CKA* mock exam, adapted to run on a **single Killercoda cluster** with an
automatic marker for every question.

The source document is paid third-party material and is not stored here. These are
re-implementations: the tasks and object names line up with it, the setup scripts
seed the state (and the faults) themselves, and the solutions are written fresh.

## Run it

```bash
# on https://killercoda.com/playgrounds/scenario/cka
git clone https://github.com/PhilaniMhlongo/CKA.git
cd CKA/ultimate
chmod +x start.sh timer.sh set-*/*.sh

./start.sh 1          # seeds the set, starts a 60-minute clock, prints the paper
./timer.sh 60         # optional, in a second tab
./set-01/grade.sh     # score it
./set-01/reset.sh     # wipe it and retake
```

## The three sets

| Set | Focus | Hardest question |
|---|---|---|
| **1** | Secrets, sidecars, shared volumes, DNS records, RBAC inspection, taints, a two-fault deployment | Q10 — an unbindable PVC *and* a bad container command |
| **2** | RBAC creation and repair, PV/PVC binding, StorageClasses, multi-pod services, Ingress, NetworkPolicy, rollback | Q8 — three faults across a deployment and its service |
| **3** | Rollout strategy, NodePort pinning, probes, secret keys, subPath mounts, etcd snapshot | Q7 — an `httpGet` probe on a container that serves no HTTP |

All three are disjoint: no question repeats across sets.

## How this differs from the original

- **One cluster, not four.** The original switches between `cluster1`–`cluster4`
  from a student-node. Killercoda gives you `controlplane` + `node01`, so the
  context-switch preamble is dropped and everything runs locally.
- **The faults are seeded, not assumed.** Every troubleshooting question here has a
  `setup.sh` that plants the fault, so the scenarios are reproducible.
- **The DNS question is correct.** The original omits `svc` from the service FQDN
  and gives `<pod_name>.local` for pod records, neither of which resolves. See
  `../docs/ultimate-cka-solutions-review.md`.
- **The unanswered questions are answered.** Set 3 includes the Practical Exercise
  tasks the original lists and never solves.

## Marking

A question is worth the weight shown on the paper, awarded pro-rata across its
checks, and the cut score is 66% — same as the real exam. The marker reads **live
cluster state**, not your YAML files, so a manifest that was never applied scores
nothing.

## Caveats worth knowing

- **Set 2 Q9 needs a policy-enforcing CNI.** On a CNI without NetworkPolicy
  support every pod can reach every other pod, so the "black pod cannot reach it"
  check will fail no matter what you write. The marker prints a note saying so.
- **Set 3 Q10 needs root on the controlplane**, and `etcdctl`. If it is missing:
  `apt-get install -y etcd-client`. On newer clusters `snapshot status` lives in
  `etcdutl`.
- **Playgrounds expire.** Run `grade.sh` before the session dies, or the work goes
  with it.
- These sets have been checked for shell and YAML validity but have **not** been
  run end-to-end against a live cluster. If a check misfires, the question text and
  the solution are the source of truth — please open an issue or fix the check.
