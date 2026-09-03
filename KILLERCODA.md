# Running these labs on Killercoda

Killercoda gives you a real kubeadm cluster in the browser with **root on the
control plane and a second node** — which is exactly what this repo's harder
labs need. It is the closest free environment to the real exam terminal.

## One-time setup, each new playground

Playground sessions are ephemeral and expire, so this runs fresh every time:

```bash
git clone https://github.com/PhilaniMhlongo/CKA.git
cd CKA
chmod +x scripts/*.sh
kubectl get nodes          # expect controlplane + node01, both Ready
```

## The one-hour paper

```bash
scripts/exam-mode.sh start --1hr
```

That builds a ~60-point paper weighted to the real CKA domain split, starts a
60-minute clock, and provisions every lab. Then:

```bash
scripts/exam-mode.sh status      # time remaining
scripts/exam-mode.sh paper       # reprint the paper
scripts/exam-mode.sh grade       # score, overall and per domain
scripts/exam-mode.sh cleanup     # tear down
```

Preview a paper without provisioning anything — useful for checking the mix
before you commit an hour to it:

```bash
scripts/exam-mode.sh plan --1hr -s 42
```

## Repeating a paper

Playgrounds are ephemeral, so re-sitting the same exam is a normal thing to want.
Sessions are archived automatically when you `grade` or `cleanup`:

```bash
scripts/exam-mode.sh history        # past papers, seeds and scores
scripts/exam-mode.sh retake         # repeat the most recent paper, exactly
scripts/exam-mode.sh retake -i 2    # repeat archived exam #2
scripts/exam-mode.sh retake -t 45   # same questions, tighter clock
```

`retake` replays the recorded question list, so it is exact. Re-running
`start -s <seed>` is *not* a reliable way to repeat a paper — the seed is only
an input to selection, and selection re-derives from whatever labs are on disk,
so the paper shifts if the repo changes. `start` warns you when that has
happened, but `retake` is the command you want.

Since the history lives in `$CKA_EXAM_HOME` (default `~/.cka-exam`) and a
Killercoda playground is wiped when it expires, copy it out if you want your
scores to survive:

```bash
tar czf ~/cka-history.tgz -C ~ .cka-exam    # then download it from the file browser
```

## Killercoda-specific notes

**Do not use `--safe` here.** It exists for single-node clusters. On Killercoda
you have control-plane access, and `--safe` would drop the etcd, kubeadm-upgrade,
kubelet and static-pod labs — 25% of the real exam's weight, and the labs you are
least likely to have practised elsewhere.

**Watch the session clock, not just the exam clock.** A playground expires on its
own schedule. Start the paper immediately after cloning, and run `grade` before
the playground dies — an expired session takes your answers with it.

**Work the paper in the order it is printed.** Labs that disturb the shared
cluster are deliberately placed last and flagged in the header. The sharp case is
Question 73 (etcd restore): it snapshots etcd, then restores that snapshot, which
silently reverts anything created *after* the snapshot. Attempted last, your
earlier answers are inside the snapshot and survive. Attempted early, it wipes
everything you do afterwards.

**Some labs intentionally break the cluster.** A downed API server, a NotReady
node, a cluster-wide DNS outage — that is the exercise, not a broken playground.
If you get genuinely stuck, `scripts/cleanup-question.sh <n>` resets that one lab.

**If a lab's setup fails**, `start` reports `SETUP FAILED` and carries on; that
lab will grade as 0. Re-run its `LabSetUp.bash` by hand if the failure looked
environmental (a slow image pull, usually).

## Practising a single topic instead

```bash
scripts/run-question.sh 73        # provision + print one lab
scripts/validate-question.sh 73   # PASS/FAIL per check
scripts/cleanup-question.sh 73
```

## A focused troubleshooting drill

Troubleshooting is 30% of the exam. This runs the multi-bug labs as one
50-minute paper:

```bash
scripts/exam-mode.sh start --questions "56 57 58 59 61 62 63 64" -t 50
```
