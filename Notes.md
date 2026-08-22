# CKA Practice Exams — Killercoda Edition

Three timed practice exams (10 questions each, 60 minutes each) built from a 30-question
CKA question bank, with an automatic marker for every set.

Designed to run on the free Killercoda CKA playground:
**https://killercoda.com/playgrounds/scenario/cka**

---

## Contents

```
.
├── bootstrap.sh              # optional: installs a working default StorageClass + metrics-server
├── start.sh                  # starts the 60-min clock for a set and prints the questions
├── timer.sh                  # live countdown (run in a second terminal tab)
├── lib/checks.sh             # shared grading helpers
├── set-01/                   # Core workloads, storage, services, RBAC        (beginner→mid)
│   ├── questions.md
│   ├── setup.sh              # seeds the broken deployment for the troubleshooting question
│   ├── grade.sh
│   └── reset.sh
├── set-02/                   # Scheduling, security, DNS, network policy       (mid)
│   ├── questions.md
│   ├── grade.sh
│   └── reset.sh
├── set-03/                   # Advanced: PV/StatefulSet/quota/Helm/Kustomize/Gateway API
│   ├── questions.md
│   ├── grade.sh
│   └── reset.sh
└── solutions/                # model answers — do not open before you're marked
```

## Exam rules (mirror the real thing)

| | |
|---|---|
| Time | 60 minutes per set |
| Questions | 10, weighted, total 100% |
| Cut score | 66% |
| Allowed | kubernetes.io/docs, kubernetes.io/blog, helm.sh/docs — nothing else |
| Not allowed | `solutions/`, AI assistants, your own notes |

Every question shows its weight. If a question is fighting you, flag it and move on —
partial credit is real: the marker scores each question by the fraction of its checks
that pass.

---

## Workflow on Killercoda

1. Open **https://killercoda.com/playgrounds/scenario/cka** and wait for the cluster.
2. Clone your repo:

   ```bash
   git clone https://github.com/<your-user>/cka-practice.git ~/cka
   cd ~/cka && chmod +x *.sh set-0*/*.sh
   ```

3. *(Optional, ~1 min)* Make storage-backed questions actually bind:

   ```bash
   ./bootstrap.sh
   ```

   This installs the local-path provisioner and creates a `standard` StorageClass plus
   metrics-server. Without it, PVCs in some questions stay `Pending` — the marker still
   grades those on spec, so it is genuinely optional.

4. Start a set (this stamps the start time and prints the paper):

   ```bash
   ./start.sh 1
   ```

   Open a second terminal tab in Killercoda and run `./timer.sh 60` for a countdown.

5. Work through `set-01/questions.md`. Do everything in the cluster — the marker only
   looks at cluster state (and a couple of files on disk), never at your YAML.

6. When the hour is up (or you're done), mark yourself:

   ```bash
   ./set-01/grade.sh
   ```

7. Review failures, then read `solutions/set-01.md`.

8. To retake a set cleanly:

   ```bash
   ./set-01/reset.sh
   ```

   Or just kill the Killercoda session and start a fresh one — that is the fastest reset.

---

## Speed setup you should be doing anyway

Run this at the start of every session until it's muscle memory:

```bash
alias k=kubectl
source <(kubectl completion bash)
complete -o default -F __start_kubectl k
export do="--dry-run=client -o yaml"
export now="--force --grace-period=0"
```

Then `k run pod --image=nginx $do > pod.yaml` is your fastest path to almost every answer.

---

## Notes on the Killercoda environment

- The playground is a kubeadm cluster, normally `controlplane` + `node01`. Any question
  that says "pick a worker node" is graded against *any* node, so `node01` (or
  `controlplane` on a single-node session) is fine.
- Internet egress works, so `helm`, `kubectl apply -f https://...` and image pulls succeed.
- A few questions intentionally leave resources `Pending` (no provisioner, no gateway
  controller, no metrics-server). Those are graded on spec, exactly as the real exam
  graders do. The question text tells you where this applies.
- Nothing here needs `sudo` beyond what the playground already gives you.

## Recommended rotation

| Day | Set | Focus if you score under 66% |
|---|---|---|
| 1 | Set 1 | Pod/Deployment/Service/ConfigMap/PVC basics, imperative commands |
| 2 | Set 2 | Scheduling, taints/tolerations, NetworkPolicy, RBAC, rollouts |
| 3 | Set 3 | StatefulSets, quotas, Helm, Kustomize, Gateway API |
| 4 | Redo weakest set | Aim to finish in 45 minutes, not 60 |
