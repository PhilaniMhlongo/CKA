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
scripts/exam-mode.sh start -n 20 -t 120   # provision 20 random labs, start a 120-min clock
scripts/exam-mode.sh start -s 42 --safe   # reproducible paper; --safe skips labs needing control-plane/multi-node
scripts/exam-mode.sh status               # time remaining
scripts/exam-mode.sh grade                # weighted score vs the 66% pass mark
scripts/exam-mode.sh cleanup              # tear down every lab in the session
```

Scoring needs no weight table: a question is worth one point per `check` in its `validate.bash`, and `grade` parses the `Results: X/Y passed` line each `validate.bash` already prints. Keeping that output format intact is what keeps exam mode working. Session state lives in `$CKA_EXAM_HOME` (default `~/.cka-exam`), never in the repo.

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

Two conventions that keep the labs exam-realistic:
- **No hints in `Questions.bash`.** State the goal and the end state, never the fault list or the fix. Diagnosis is the skill being tested. Hints belong in `SolutionNotes.bash`, which the learner opens deliberately.
- **Mark cluster requirements.** If a lab needs control-plane node access or more than one node, put `# REQUIRES: ...` (or "at least 2 schedulable") in `Questions.bash`. `exam-mode.sh --safe` filters on exactly that marker.

Negative checks (`! kubectl get ...`) pass when the API server is simply unreachable. Gate them on a positive check first, e.g. `kubectl get namespace X && ! kubectl get configmap Y -n X`.

## Working directories used by labs

Some `LabSetUp.bash` scripts write generated YAML into a working directory under the repo (e.g. `Question-13-Network-Policy` creates `./network-policies/`), respecting a `WORKDIR` env var override. `cleanup.bash` for that question removes the same directory. Preserve this pattern (generate into the question's local working directory, not `/root` or other fixed paths) if you touch these scripts — a prior fix (see git history for Question 13) moved setup away from writing to the root folder specifically to avoid local permission issues.
