# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A collection of standalone CKA (Certified Kubernetes Administrator) practice labs. Each `Question-N-Topic/` directory is a self-contained scenario that sets up cluster state, poses a task, and validates the learner's solution. There is no application code, build step, or test suite in the traditional sense — the "tests" are `validate.bash` scripts that run `kubectl` checks against a live cluster.

These labs are meant to run inside a real (or Killercoda) Kubernetes cluster with `kubectl` already configured against it. There is no CI here that spins up a cluster — everything assumes an existing cluster context.

## Commands

Driver scripts in `scripts/` resolve a question either by number or by directory name:

```bash
scripts/run-question.sh 5          # runs LabSetUp.bash, then prints Questions.bash + points to SolutionNotes.bash
scripts/validate-question.sh 5     # runs validate.bash, prints PASS/FAIL per check
scripts/validate-question.sh all   # runs validate.bash for every question, prints a summary, exit code reflects failures
scripts/cleanup-question.sh 5      # runs cleanup.bash to tear down resources
scripts/cleanup-question.sh all
```

Directory names can also be passed directly, e.g. `scripts/validate-question.sh Question-5-HPA`.

`scripts/exam-mode.sh` runs several questions as one timed, scored session (the killer.sh / real-exam shape) instead of one isolated lab:

```bash
scripts/exam-mode.sh start --1hr          # 60-min paper (Killercoda playground size)
scripts/exam-mode.sh start --2hr          # 120-min paper (full exam)
scripts/exam-mode.sh start -t 90          # any duration; paper size follows the clock
scripts/exam-mode.sh start -n 12 -t 60    # force a question count instead
scripts/exam-mode.sh plan --1hr -s 42     # preview a paper WITHOUT provisioning anything
scripts/exam-mode.sh retake               # repeat the last paper, exactly
scripts/exam-mode.sh retake -i 3 -t 45    # repeat archived exam #3 on a tighter clock
scripts/exam-mode.sh history              # past papers and scores
scripts/exam-mode.sh status               # time remaining
scripts/exam-mode.sh grade                # weighted score, overall and per domain
scripts/exam-mode.sh cleanup              # tear down every lab in the session
```

Scoring needs no weight table: a question is worth one point per `check` in its `validate.bash`, and `grade` parses the `Results: X/Y passed` line each `validate.bash` already prints. Keeping that output format intact is what keeps exam mode working. Session state lives in `$CKA_EXAM_HOME` (default `~/.cka-exam`), never in the repo.

**Question selection is weighted to the real CKA domain split** (Troubleshooting 30 / Cluster Architecture 25 / Services & Networking 20 / Workloads & Scheduling 15 / Storage 10). The unit of weighting is *points*, not question count, so each domain is filled until it holds roughly its share of the paper's points. This matters because the corpus itself is skewed — Workloads is ~29% of all points and Troubleshooting only ~17%, so an unweighted paper under-tests the largest exam domain. `--uniform` restores the old uniform-random behaviour.

Paper size is budgeted at ~1 point per minute (`PACE` in the script), which reproduces the real exam's pace of roughly 15-20 tasks in 120 minutes. `-n` overrides that and targets a question count instead.

**Repeating a paper: use `retake`, not the seed.** A seed reproduces a paper only while the corpus is unchanged — selection is re-derived from the labs on disk, so adding a lab or editing a `validate.bash` silently changes what a seed means (verified: introducing one extra lab changes 2 of 14 picks for the same seed). Every session is therefore archived to `$CKA_EXAM_HOME/history/` on `grade` or `cleanup` with its exact question list, and `retake` replays that list. `start -s X` warns when the corpus fingerprint has drifted since that seed was last used. Labs that have since been deleted are dropped from a retake with a warning rather than failing it.

There is no separate "single test" concept beyond running validation for one question directory — each question's `validate.bash` is itself the full test for that scenario.

## Per-question structure

Every `Question-N-Topic/` directory follows the same five-file convention:

- `LabSetUp.bash` — idempotent setup (`kubectl apply` of dry-run YAML, namespace creation, etc.) that builds the starting state for the scenario. Should be safe to re-run.
- `Questions.bash` — not executed; a commented scenario/task description plus a YouTube walkthrough link. Read as text via `cat`, not run.
- `SolutionNotes.bash` — commented step-by-step solution/hint, also not meant to be executed as-is (may contain placeholder pod names the learner must substitute).
- `validate.bash` — automated checks. Follows a consistent `check "<description>" <command...>` pattern that increments PASS/FAIL/TOTAL counters and exits non-zero (`$FAIL`) if anything failed. Some checks shell out to `python3 -c` for JSON parsing of `kubectl ... -o json` output rather than `jq`.
- `cleanup.bash` — deletes everything the setup created (namespaces, cluster-scoped objects, generated files/dirs), using `--ignore-not-found` so it's safe to run even if setup partially failed.

When editing or adding a question, keep this five-file shape and the PASS/FAIL check-counter style in `validate.bash` consistent with existing questions (see `Question-13-Network-Policy/validate.bash` for a representative example).

## Adding a new question

New questions are numbered sequentially (`Question-N-Short-Topic-Name/`). When adding one, also update:
- The `seq 1 N` upper bound in `scripts/validate-question.sh` and `scripts/cleanup-question.sh` (currently `74` in both `all` loops — bump this or the new question will be silently skipped by `all`).
- The topics table in `README.md`.

Every new `Questions.bash` must also carry a **`# DOMAIN:`** marker on the second line — one of `Troubleshooting`, `ClusterArchitecture`, `ServicesNetworking`, `WorkloadsScheduling`, `Storage`. `exam-mode.sh` reads it for weighted selection and for the per-domain score breakdown; a lab without one falls into an `Unclassified` bucket and will never be picked by a weighted paper.

Conventions that keep the labs exam-realistic:
- **No hints in `Questions.bash`.** State the goal and the end state, never the fault list or the fix. Diagnosis is the skill being tested. Hints belong in `SolutionNotes.bash`, which the learner opens deliberately. (The `# DOMAIN:` marker is stripped before the exam paper is printed, so it is tooling metadata rather than a hint.)
- **Mark cluster requirements.** If a lab needs control-plane node access or more than one node, put `# REQUIRES: ...` (or "at least 2 schedulable") in `Questions.bash`. `exam-mode.sh --safe` filters on exactly that marker.
- **Mark labs that disturb their neighbours.** A lab whose solution downs the control plane, cordons a node, breaks cluster DNS or rolls etcd back gets a `# DISRUPTIVE: <reason>` line. `exam-mode.sh` always orders those last in a paper so they cannot destroy the candidate's answers to earlier questions — Question 73 (etcd restore) is the sharp case: restoring a snapshot taken mid-exam silently reverts anything created after it.

## Working directories used by labs

Some `LabSetUp.bash` scripts write generated YAML into a working directory under the repo (e.g. `Question-13-Network-Policy` creates `./network-policies/`), respecting a `WORKDIR` env var override. `cleanup.bash` for that question removes the same directory. Preserve this pattern (generate into the question's local working directory, not `/root` or other fixed paths) if you touch these scripts — a prior fix (see git history for Question 13) moved setup away from writing to the root folder specifically to avoid local permission issues.
