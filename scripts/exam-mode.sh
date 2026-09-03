#!/bin/bash
# ============================================================
# exam-mode.sh - timed, weighted, multi-question exam simulation
#
# Runs a set of questions as ONE scored session against the clock, the
# way killer.sh / the real CKA works - rather than one isolated lab at
# a time.
#
# Usage:
#   scripts/exam-mode.sh start --1hr          # 60-minute paper (Killercoda-sized)
#   scripts/exam-mode.sh start --2hr          # 120-minute paper (full exam)
#   scripts/exam-mode.sh start -t 90          # any duration; question count follows
#   scripts/exam-mode.sh start -n 12 -t 60    # force a question count
#   scripts/exam-mode.sh start -s 42 --1hr    # reproducible paper
#   scripts/exam-mode.sh start --questions "5 13 56 66"
#   scripts/exam-mode.sh plan --1hr           # preview a paper WITHOUT provisioning
#   scripts/exam-mode.sh retake               # REPEAT the last paper, exactly
#   scripts/exam-mode.sh retake -i 3 -t 45    # repeat exam #3 on a tighter clock
#   scripts/exam-mode.sh history              # past papers and scores
#   scripts/exam-mode.sh status               # time remaining
#   scripts/exam-mode.sh paper                # reprint the question paper
#   scripts/exam-mode.sh grade                # score, overall and per domain
#   scripts/exam-mode.sh cleanup              # tear down the whole session
#
# Question selection is WEIGHTED to the real CKA domain split:
#   Troubleshooting 30 / Cluster Architecture 25 / Services & Networking 20
#   / Workloads & Scheduling 15 / Storage 10
# The unit of weighting is POINTS, not questions: a question is worth one
# point per `check` in its validate.bash, so a paper is built until each
# domain has roughly its share of the total points. Pass --uniform for the
# old behaviour (uniform random across all questions).
#
# Sizing: the paper is budgeted at ~1 point per minute, which matches the
# real exam's pace (~15-20 tasks in 120 minutes). -n overrides that and
# targets a question count instead.
#
# Flags:
#   --safe    skip labs needing control-plane access or a 2nd node.
#             On Killercoda you have both, so DON'T use --safe - it drops
#             etcd, kubeadm upgrade and kubelet labs, which are 25% of the exam.
#   --uniform ignore domain weighting (old behaviour)
#
# Labs marked "# DISRUPTIVE:" in their Questions.bash disturb their
# neighbours (a downed control plane, a cordoned node, an etcd rollback).
# They are always placed LAST in the paper so they cannot destroy your
# answers to the other questions. Question 73 (etcd restore) rolls the
# cluster back to its snapshot - attempt it last, exactly as the paper orders it.
#
# Repeating a paper: `retake` replays the exact recorded question list and is
# the reliable way to re-sit an exam. A seed alone only reproduces a paper
# while the lab collection is unchanged - selection is re-derived from what is
# on disk, so adding a lab or editing a validate.bash silently changes what a
# seed means. Every session is archived on grade/cleanup, and `start -s X`
# warns when the corpus has drifted since that seed was last used.
#
# Pass mark is 66%, matching the real CKA.
# ============================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

STATE_DIR="${CKA_EXAM_HOME:-$HOME/.cka-exam}"
SESSION="$STATE_DIR/session.env"
PAPER="$STATE_DIR/exam-paper.txt"

DEFAULT_MINUTES=120
PASS_MARK=66

# Real CKA domain weights. These drive question selection AND the per-domain
# score breakdown in `grade`. Keep in sync with the markers in Questions.bash.
DOMAIN_WEIGHTS="Troubleshooting:30 ClusterArchitecture:25 ServicesNetworking:20 WorkloadsScheduling:15 Storage:10"

# Paper size: target points = minutes * PACE. One point = one validate.bash
# check, and ~1 check per minute matches the real exam's pace.
PACE=1.0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# -- helpers --------------------------------------------------

all_question_dirs() {
  find "$BASE_DIR" -maxdepth 1 -type d -name "Question-*" -printf "%f\n" \
    | sort -t- -k2 -n
}

# A question needs privileged cluster access (control-plane node, >1 node)
# if its text carries the REQUIRES/needs marker.
needs_special_cluster() {
  grep -qE "REQUIRES:|at least 2 schedulable" "$BASE_DIR/$1/Questions.bash" 2>/dev/null
}

question_number() {
  echo "$1" | cut -d- -f2
}

# Domain comes from the "# DOMAIN: <name>" marker in Questions.bash.
question_domain() {
  local d
  d=$(grep -m1 '^# DOMAIN:' "$BASE_DIR/$1/Questions.bash" 2>/dev/null | sed 's/^# DOMAIN: *//')
  echo "${d:-Unclassified}"
}

# A lab that disturbs its neighbours (downed control plane, cordoned node,
# etcd rollback) carries a "# DISRUPTIVE: <reason>" marker.
is_disruptive() {
  grep -q '^# DISRUPTIVE:' "$BASE_DIR/$1/Questions.bash" 2>/dev/null
}

disruptive_reason() {
  grep -m1 '^# DISRUPTIVE:' "$BASE_DIR/$1/Questions.bash" 2>/dev/null | sed 's/^# DISRUPTIVE: *//'
}

# Points for a question = number of checks in its validate.bash.
question_weight() {
  local w
  w=$(grep -cE '^\s*check "' "$BASE_DIR/$1/validate.bash" 2>/dev/null || echo 0)
  [[ "$w" -gt 0 ]] && echo "$w" || echo 1
}

require_session() {
  if [[ ! -f "$SESSION" ]]; then
    echo -e "${RED}No exam session in progress. Start one with:${NC}" >&2
    echo "  scripts/exam-mode.sh start" >&2
    exit 1
  fi
  # shellcheck disable=SC1090
  source "$SESSION"
  # Sessions written by older versions lack these; keep `set -u` happy.
  MODE="${MODE:-weighted}"
  SAFE="${SAFE:-0}"
  ORIGIN="${ORIGIN:-fresh}"
  FINGERPRINT="${FINGERPRINT:-}"
}

fmt_duration() {
  local total=$1 sign=""
  if [[ $total -lt 0 ]]; then sign="-"; total=$(( -total )); fi
  printf "%s%d:%02d:%02d" "$sign" $((total/3600)) $(((total%3600)/60)) $((total%60))
}



# -- reproducibility ------------------------------------------
#
# A seed only reproduces a paper while the corpus is unchanged: selection is
# re-derived from the labs present on disk, so adding a lab or changing a
# validate.bash silently changes what a seed means. We therefore record the
# exact question list of every session and replay THAT (see `retake`), and
# fingerprint the corpus so a drifted seed can be reported rather than
# silently honoured.
HISTORY_DIR="$STATE_DIR/history"

corpus_fingerprint() {
  all_question_dirs | while read -r d; do
    [[ -z "$d" ]] && continue
    printf '%s:%s\n' "$d" "$(question_weight "$d")"
  done | md5sum | cut -c1-12
}

# Rebuild the exact command that reproduces a session, losing no flags.
replay_command() {
  local seed="$1" minutes="$2" mode="$3" safe="$4"
  local cmd="scripts/exam-mode.sh start -s $seed -t $minutes"
  [[ "$safe" == "1" ]] && cmd+=" --safe"
  [[ "$mode" == "uniform" ]] && cmd+=" --uniform"
  echo "$cmd"
}

# Copy the finished session into the history archive so it stays replayable
# after cleanup. Idempotent: a session is archived at most once.
archive_session() {
  local score="${1:-}"
  [[ -f "$SESSION" ]] || return 0
  grep -q '^ARCHIVED=1' "$SESSION" && return 0
  mkdir -p "$HISTORY_DIR"
  local stamp file seed
  stamp=$(date '+%Y%m%d-%H%M%S')
  # Read the seed from the file rather than caller state: archive_session is
  # called from paths that have not sourced the session.
  seed=$(grep -m1 '^SEED=' "$SESSION" | cut -d= -f2)
  file="$HISTORY_DIR/${stamp}-seed${seed:-unknown}.env"
  { cat "$SESSION"; echo "ARCHIVED_AT=$stamp"; [[ -n "$score" ]] && echo "SCORE=$score"; } > "$file"
  echo "ARCHIVED=1" >> "$SESSION"
  echo "$file"
}

# Resolve a history record from: nothing (most recent), -i INDEX, or -s SEED.
find_history_record() {
  local kind="$1" value="${2:-}"
  [[ -d "$HISTORY_DIR" ]] || return 1
  local files
  files=$(ls -1 "$HISTORY_DIR"/*.env 2>/dev/null | sort)
  [[ -z "$files" ]] || true
  case "$kind" in
    last)  echo "$files" | tail -1 ;;
    index) echo "$files" | sed -n "${value}p" ;;
    seed)  echo "$files" | grep -E "seed${value}\.env$" | tail -1 ;;
  esac
}

# -- selection engine -----------------------------------------
#
# Builds "dir:domain:points" for every candidate, then hands the list to a
# small python allocator that fills each domain up to its share of the
# points budget. Returns selected directories, one per line, ordered:
# ordinary questions by number first, then DISRUPTIVE ones by number, so a
# lab that breaks the cluster can never wreck your earlier answers.
select_questions() {
  local seed="$1" target_points="$2" mode="$3" safe="$4"
  local candidates spec=""

  candidates=$(all_question_dirs)
  if [[ $safe -eq 1 ]]; then
    local filtered=""
    while read -r d; do
      [[ -z "$d" ]] && continue
      needs_special_cluster "$d" || filtered+="$d"$'\n'
    done <<< "$candidates"
    candidates=$(echo "$filtered" | grep -v '^$')
  fi

  while read -r d; do
    [[ -z "$d" ]] && continue
    local dis=0
    is_disruptive "$d" && dis=1
    spec+="$d:$(question_domain "$d"):$(question_weight "$d"):$dis"$'\n'
  done <<< "$candidates"

  printf '%s' "$spec" | python3 -c '
import sys, random

seed, target, mode = sys.argv[1], float(sys.argv[2]), sys.argv[3]
weights = dict((w.split(":")[0], float(w.split(":")[1])) for w in sys.argv[4:])

items = []
for line in sys.stdin.read().splitlines():
    if not line.strip():
        continue
    d, dom, pts, dis = line.rsplit(":", 3)
    items.append((d, dom, int(pts), dis == "1"))

random.seed(seed)

if mode == "uniform":
    # Old behaviour: uniform random until the points budget is met.
    pool = items[:]
    random.shuffle(pool)
    picked, acc = [], 0
    for it in pool:
        if acc >= target:
            break
        picked.append(it)
        acc += it[2]
else:
    by_domain = {}
    for it in items:
        by_domain.setdefault(it[1], []).append(it)
    for v in by_domain.values():
        random.shuffle(v)

    picked = []
    # Largest domains first so rounding slack lands on the small ones.
    for dom in sorted(weights, key=lambda k: -weights[k]):
        pool = by_domain.get(dom, [])
        if not pool:
            continue
        dom_target = target * weights[dom] / 100.0
        # First pick: prefer a question that actually fits the domain budget,
        # so one oversized lab cannot dominate a short paper. If none fits
        # (small budget, big labs) fall back to the smallest available.
        fits = [it for it in pool if it[2] <= dom_target]
        first = random.choice(fits) if fits else min(pool, key=lambda it: it[2])
        pool = [first] + [it for it in pool if it is not first]

        acc = 0
        for it in pool:
            if acc == 0:
                # Every weighted domain is represented at least once.
                picked.append(it); acc += it[2]; continue
            if acc >= dom_target:
                break
            # Take it only if it lands closer to the target than stopping does.
            # A single oversized candidate is skipped, not treated as the end
            # of the domain - otherwise one big lab starves its whole domain.
            # Hard ceiling keeps a paper close to its time budget.
            if acc + it[2] > dom_target * 1.15:
                continue
            if abs(acc + it[2] - dom_target) <= abs(acc - dom_target):
                picked.append(it); acc += it[2]

# Ordinary questions first, disruptive ones last - both by question number.
def num(it):
    return int(it[0].split("-")[1])
picked.sort(key=lambda it: (it[3], num(it)))
print("\n".join(it[0] for it in picked))
' "$seed" "$target_points" "$mode" $DOMAIN_WEIGHTS
}

# Prints "Domain pts pct" rows for a set of question dirs.
domain_breakdown() {
  local dirs="$1" spec=""
  while read -r d; do
    [[ -z "$d" ]] && continue
    spec+="$(question_domain "$d"):$(question_weight "$d")"$'\n'
  done <<< "$dirs"
  printf '%s' "$spec" | python3 -c '
import sys
weights = dict((w.split(":")[0], float(w.split(":")[1])) for w in sys.argv[1:])
agg, qs = {}, {}
for line in sys.stdin.read().splitlines():
    if not line.strip():
        continue
    dom, pts = line.rsplit(":", 1)
    agg[dom] = agg.get(dom, 0) + int(pts)
    qs[dom] = qs.get(dom, 0) + 1
total = sum(agg.values()) or 1
for dom in sorted(weights, key=lambda k: -weights[k]):
    got = agg.get(dom, 0)
    print(f"  {dom:22} {qs.get(dom,0):2d} q  {got:3d} pts   {got/total*100:5.1f}%  (target {weights[dom]:.0f}%)")
for dom in sorted(d for d in agg if d not in weights):
    got = agg[dom]
    print(f"  {dom:22} {qs[dom]:2d} q  {got:3d} pts   {got/total*100:5.1f}%  (unweighted)")
' $DOMAIN_WEIGHTS
}

# -- start ----------------------------------------------------

# Shared by `start` and `plan`: parses flags and computes the selection.
# Sets: SEL_QUESTIONS SEL_SEED SEL_MINUTES SEL_MODE SEL_SAFE SEL_TARGET
parse_and_select() {
  local minutes=$DEFAULT_MINUTES
  local seed=$RANDOM
  local safe=0
  local mode="weighted"
  local explicit=""
  local count=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n) count="$2"; shift 2 ;;
      -t) minutes="$2"; shift 2 ;;
      -s) seed="$2"; shift 2 ;;
      --1hr|--1h) minutes=60; shift ;;
      --2hr|--2h) minutes=120; shift ;;
      --safe) safe=1; shift ;;
      --uniform) mode="uniform"; shift ;;
      --weighted) mode="weighted"; shift ;;
      --questions) explicit="$2"; shift 2 ;;
      *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
  done

  local selected="" target=0
  if [[ -n "$explicit" ]]; then
    for n in $explicit; do
      local d
      d=$(all_question_dirs | grep -E "^Question-${n}-" | head -1)
      if [[ -z "$d" ]]; then
        echo -e "${RED}No question directory for '$n'${NC}" >&2
        exit 1
      fi
      selected+="$d"$'\n'
    done
    selected=$(echo "$selected" | grep -v '^$')
  else
    if [[ -n "$count" ]]; then
      # -n given: convert a question count into a points budget using the
      # average question size, so the same allocator can serve both.
      target=$(all_question_dirs | { tot=0; n=0
        while read -r d; do [[ -z "$d" ]] && continue
          tot=$(( tot + $(question_weight "$d") )); n=$((n+1)); done
        python3 -c "print(f'{$count * $tot / max($n,1):.1f}')"; })
    else
      target=$(python3 -c "print(f'{$minutes * $PACE:.1f}')")
    fi
    selected=$(select_questions "$seed" "$target" "$mode" "$safe")
  fi

  SEL_QUESTIONS="$selected"
  SEL_SEED="$seed"
  SEL_MINUTES="$minutes"
  SEL_MODE="$mode"
  SEL_SAFE="$safe"
  SEL_TARGET="$target"
}

# Writes the printable question paper to $1 for the given selection.
write_paper() {
  local out="$1" n_selected total_weight=0 minutes="$SEL_MINUTES"

  while read -r d; do
    [[ -z "$d" ]] && continue
    total_weight=$(( total_weight + $(question_weight "$d") ))
  done <<< "$SEL_QUESTIONS"
  n_selected=$(echo "$SEL_QUESTIONS" | grep -c .)

  {
    echo "============================================================"
    echo " CKA PRACTICE EXAM"
    echo "============================================================"
    echo " Questions:  $n_selected   ($total_weight points)"
    echo " Time limit: ${minutes} minutes"
    echo " Pass mark:  ${PASS_MARK}%   (need $(python3 -c "import math;print(math.ceil($total_weight*$PASS_MARK/100))") points)"
    echo " Selection:  $SEL_MODE$([[ $SEL_SAFE -eq 1 ]] && echo ' --safe')"
    echo " Seed:       $SEED_LABEL"
    echo " Deadline:   PENDING"
    echo "============================================================"
    echo ""
    echo " Domain mix:"
    domain_breakdown "$SEL_QUESTIONS"
    echo ""

    local disruptive_list=""
    while read -r d; do
      [[ -z "$d" ]] && continue
      is_disruptive "$d" && disruptive_list+="   - $d: $(disruptive_reason "$d")"$'\n'
    done <<< "$SEL_QUESTIONS"
    if [[ -n "$disruptive_list" ]]; then
      echo " !! These labs disturb the shared cluster and are placed LAST."
      echo "    Work the paper in order and attempt them only at the end:"
      printf '%s' "$disruptive_list"
      echo ""
    fi

    local idx=0
    while read -r d; do
      [[ -z "$d" ]] && continue
      idx=$((idx + 1))
      local w pct
      w=$(question_weight "$d")
      pct=$(python3 -c "print(f'{$w / $total_weight * 100:.1f}')")
      echo "------------------------------------------------------------"
      echo "QUESTION $idx of $n_selected   [$d]   ${w} pts / ${pct}%"
      echo "------------------------------------------------------------"
      # The DOMAIN marker is tooling metadata, not part of the paper.
      grep -v '^# DOMAIN:' "$BASE_DIR/$d/Questions.bash"
      echo ""
    done <<< "$SEL_QUESTIONS"
  } > "$out"
}

# -- plan (preview a paper without touching the cluster) -------

cmd_plan() {
  parse_and_select "$@"
  SEED_LABEL="$SEL_SEED   (reuse with -s $SEL_SEED for the same paper)"
  local tmp="$STATE_DIR/plan-paper.txt"
  mkdir -p "$STATE_DIR"
  write_paper "$tmp"
  sed -n '1,/^$/p' "$tmp" | head -20
  echo " Domain mix:"
  domain_breakdown "$SEL_QUESTIONS"
  echo ""
  echo " Questions in paper order:"
  local idx=0
  while read -r d; do
    [[ -z "$d" ]] && continue
    idx=$((idx+1))
    local tag=""
    is_disruptive "$d" && tag=" ${YELLOW}[disruptive - do last]${NC}"
    printf "  %2d. %-42s %-22s %2d pts%b\n" "$idx" "$d" "$(question_domain "$d")" "$(question_weight "$d")" "$tag"
  done <<< "$SEL_QUESTIONS"
  echo ""
  echo -e "${CYAN}This was a preview - nothing was provisioned.${NC}"
  echo "Start it for real with the same paper:"
  echo "  $(replay_command "$SEL_SEED" "$SEL_MINUTES" "$SEL_MODE" "$SEL_SAFE")"
}

# -- start ----------------------------------------------------

# Provisions $SEL_QUESTIONS, writes the session + paper, and starts the clock.
# Shared by `start` and `retake`.
provision_and_launch() {
  local selected="$SEL_QUESTIONS"
  local seed="$SEL_SEED"
  local minutes="$SEL_MINUTES"
  local origin="${1:-fresh}"

  mkdir -p "$STATE_DIR"

  local n_selected total_weight=0
  n_selected=$(echo "$selected" | grep -c .)
  while read -r d; do
    [[ -z "$d" ]] && continue
    total_weight=$(( total_weight + $(question_weight "$d") ))
  done <<< "$selected"

  local start_epoch deadline_epoch
  start_epoch=$(date +%s)
  deadline_epoch=$(( start_epoch + minutes * 60 ))

  if [[ "$origin" == "retake" ]]; then
    SEED_LABEL="$seed   (RETAKE - replayed from a recorded paper, not re-derived)"
  else
    SEED_LABEL="$seed   (repeat with: $(replay_command "$seed" "$minutes" "$SEL_MODE" "$SEL_SAFE"))"
  fi
  write_paper "$PAPER"

  # -- persist the session ------------------------------------
  {
    echo "SEED=$seed"
    echo "START_EPOCH=$start_epoch"
    echo "DEADLINE_EPOCH=$deadline_epoch"
    echo "LIMIT_MINUTES=$minutes"
    echo "TOTAL_WEIGHT=$total_weight"
    echo "MODE=$SEL_MODE"
    echo "SAFE=$SEL_SAFE"
    echo "ORIGIN=$origin"
    echo "FINGERPRINT=$(corpus_fingerprint)"
    echo "QUESTIONS=\"$(echo "$selected" | tr '\n' ' ')\""
  } > "$SESSION"

  # -- provision every lab ------------------------------------
  echo -e "${CYAN}Provisioning $n_selected labs. This takes a moment...${NC}"
  echo ""
  local failed_setup=""
  while read -r d; do
    [[ -z "$d" ]] && continue
    printf "  %-45s " "$d"
    if bash "$BASE_DIR/$d/LabSetUp.bash" >/dev/null 2>&1; then
      echo -e "${GREEN}ready${NC}"
    else
      echo -e "${RED}SETUP FAILED${NC}"
      failed_setup+="$d "
    fi
  done <<< "$selected"

  if [[ -n "$failed_setup" ]]; then
    echo ""
    echo -e "${YELLOW}Setup failed for: $failed_setup${NC}"
    echo "Those labs will still be graded and will score 0. Re-run their"
    echo "LabSetUp.bash by hand if the failure was environmental."
  fi

  # The clock starts once the cluster is actually ready.
  start_epoch=$(date +%s)
  deadline_epoch=$(( start_epoch + minutes * 60 ))
  sed -i "s/^START_EPOCH=.*/START_EPOCH=$start_epoch/" "$SESSION"
  sed -i "s/^DEADLINE_EPOCH=.*/DEADLINE_EPOCH=$deadline_epoch/" "$SESSION"
  sed -i "s|^ Deadline:.*| Deadline:   $(date -d "@$deadline_epoch" '+%Y-%m-%d %H:%M:%S')|" "$PAPER"

  echo ""
  cat "$PAPER"
  echo ""
  echo -e "${BOLD}Clock started. Deadline $(date -d "@$deadline_epoch" '+%H:%M:%S').${NC}"
  echo "  scripts/exam-mode.sh status   - time remaining"
  echo "  scripts/exam-mode.sh paper    - reprint the paper"
  echo "  scripts/exam-mode.sh grade    - finish and score"
  echo ""
  echo -e "${YELLOW}Note:${NC} all labs share one cluster. Any lab flagged DISRUPTIVE"
  echo "above is placed last on purpose - work the paper in order so a downed"
  echo "control plane or an etcd rollback cannot undo your earlier answers."
  echo "Use --safe for a clean run on a single-node cluster (but on Killercoda"
  echo "you have control-plane access, so --safe only costs you exam coverage)."
}

# Refuses to clobber a live session unless --force was passed.
guard_existing_session() {
  local force="$1"
  [[ -f "$SESSION" ]] || return 0
  if [[ "$force" == "1" ]]; then
    echo -e "${YELLOW}Discarding the existing session (--force).${NC}"
    echo -e "${YELLOW}Its labs are NOT torn down - run cleanup first if you wanted that.${NC}"
    archive_session >/dev/null
    rm -f "$SESSION" "$PAPER"
    return 0
  fi
  echo -e "${YELLOW}An exam session already exists.${NC}"
  # shellcheck disable=SC1090
  source "$SESSION"
  echo "  Started with seed $SEED for ${LIMIT_MINUTES} minutes."
  echo ""
  echo "Finish it, or clear it first:"
  echo "  scripts/exam-mode.sh grade      # score it (archives it for retake)"
  echo "  scripts/exam-mode.sh cleanup    # tear the labs down and clear it"
  echo "  ... or re-run with --force to discard it without tearing labs down."
  exit 1
}

# -- start ----------------------------------------------------

cmd_start() {
  local force=0 passthru=()
  for a in "$@"; do
    if [[ "$a" == "--force" ]]; then force=1; else passthru+=("$a"); fi
  done
  guard_existing_session "$force"

  parse_and_select "${passthru[@]}"

  # Warn if this seed produced a different paper last time because the
  # corpus changed underneath it.
  if [[ -d "$HISTORY_DIR" ]]; then
    local prev fp_now fp_then
    prev=$(find_history_record seed "$SEL_SEED" || true)
    if [[ -n "$prev" && -f "$prev" ]]; then
      fp_now=$(corpus_fingerprint)
      fp_then=$(grep -m1 '^FINGERPRINT=' "$prev" | cut -d= -f2)
      if [[ -n "$fp_then" && "$fp_now" != "$fp_then" ]]; then
        echo -e "${YELLOW}Note: the lab collection has changed since seed $SEL_SEED was last used,${NC}"
        echo -e "${YELLOW}so this paper will NOT match that run. To replay it exactly:${NC}"
        echo "  scripts/exam-mode.sh retake -s $SEL_SEED"
        echo ""
      fi
    fi
  fi

  provision_and_launch fresh
}

# -- retake (replay a recorded paper exactly) ------------------

cmd_retake() {
  local kind="last" value="" minutes="" force=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -i) kind="index"; value="$2"; shift 2 ;;
      -s) kind="seed";  value="$2"; shift 2 ;;
      -t) minutes="$2"; shift 2 ;;
      --force) force=1; shift ;;
      last) kind="last"; shift ;;
      *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
  done

  local rec
  rec=$(find_history_record "$kind" "$value" || true)
  if [[ -z "$rec" || ! -f "$rec" ]]; then
    echo -e "${RED}No recorded exam found for that reference.${NC}" >&2
    echo "List what is available with: scripts/exam-mode.sh history" >&2
    exit 1
  fi

  guard_existing_session "$force"

  # shellcheck disable=SC1090
  local REC_SEED REC_MIN REC_MODE REC_SAFE REC_Q REC_FP
  REC_SEED=$(grep -m1 '^SEED=' "$rec" | cut -d= -f2)
  REC_MIN=$(grep -m1 '^LIMIT_MINUTES=' "$rec" | cut -d= -f2)
  REC_MODE=$(grep -m1 '^MODE=' "$rec" | cut -d= -f2)
  REC_SAFE=$(grep -m1 '^SAFE=' "$rec" | cut -d= -f2)
  REC_FP=$(grep -m1 '^FINGERPRINT=' "$rec" | cut -d= -f2)
  REC_Q=$(grep -m1 '^QUESTIONS=' "$rec" | sed 's/^QUESTIONS="//; s/"$//')

  # Drop any lab that no longer exists, rather than failing the whole retake.
  local kept="" dropped=""
  for d in $REC_Q; do
    if [[ -d "$BASE_DIR/$d" ]]; then kept+="$d"$'\n'; else dropped+="$d "; fi
  done
  kept=$(echo "$kept" | grep -v '^$')
  if [[ -z "$kept" ]]; then
    echo -e "${RED}None of that paper's labs still exist.${NC}" >&2
    exit 1
  fi
  if [[ -n "$dropped" ]]; then
    echo -e "${YELLOW}These labs no longer exist and were dropped: $dropped${NC}"
  fi

  SEL_QUESTIONS="$kept"
  SEL_SEED="$REC_SEED"
  SEL_MINUTES="${minutes:-$REC_MIN}"
  SEL_MODE="${REC_MODE:-weighted}"
  SEL_SAFE="${REC_SAFE:-0}"

  echo -e "${CYAN}Retaking the paper from $(basename "$rec").${NC}"
  local prev_score
  prev_score=$(grep -m1 '^SCORE=' "$rec" | cut -d= -f2 || true)
  [[ -n "$prev_score" ]] && echo "Last time you scored ${prev_score}%."
  if [[ -n "$REC_FP" && "$REC_FP" != "$(corpus_fingerprint)" ]]; then
    echo -e "${YELLOW}(The labs themselves have changed since then, so scores are not"
    echo -e "strictly comparable - the question LIST is identical.)${NC}"
  fi
  [[ -n "$minutes" ]] && echo "Clock overridden to ${minutes} minutes."
  echo ""

  provision_and_launch retake
}

# -- history --------------------------------------------------

cmd_history() {
  if [[ ! -d "$HISTORY_DIR" ]] || [[ -z "$(ls -A "$HISTORY_DIR" 2>/dev/null)" ]]; then
    echo "No graded exams recorded yet."
    echo "Sessions are archived when you run 'grade' or 'cleanup'."
    return 0
  fi
  printf "  %-3s %-17s %-8s %-6s %-6s %s\n" "#" "WHEN" "SEED" "MINS" "SCORE" "QUESTIONS"
  local i=0
  for f in $(ls -1 "$HISTORY_DIR"/*.env | sort); do
    i=$((i+1))
    local when seed mins score nq
    when=$(grep -m1 '^ARCHIVED_AT=' "$f" | cut -d= -f2)
    seed=$(grep -m1 '^SEED=' "$f" | cut -d= -f2)
    mins=$(grep -m1 '^LIMIT_MINUTES=' "$f" | cut -d= -f2)
    score=$(grep -m1 '^SCORE=' "$f" | cut -d= -f2)
    nq=$(grep -m1 '^QUESTIONS=' "$f" | sed 's/^QUESTIONS="//; s/"$//' | wc -w)
    printf "  %-3s %-17s %-8s %-6s %-6s %s\n" "$i" "$when" "$seed" "$mins" "${score:-n/a}" "$nq"
  done
  echo ""
  echo "Replay one exactly:  scripts/exam-mode.sh retake -i <#>"
  echo "Most recent:         scripts/exam-mode.sh retake"
  echo "Tighter clock:       scripts/exam-mode.sh retake -i <#> -t 45"
}

# -- status ---------------------------------------------------

cmd_status() {
  require_session
  local now remaining elapsed
  now=$(date +%s)
  remaining=$(( DEADLINE_EPOCH - now ))
  elapsed=$(( now - START_EPOCH ))

  echo "Questions: $(echo "$QUESTIONS" | wc -w)   Seed: $SEED"
  echo "Elapsed:   $(fmt_duration $elapsed) of ${LIMIT_MINUTES}:00 minutes"
  if [[ $remaining -ge 0 ]]; then
    echo -e "Remaining: ${GREEN}$(fmt_duration $remaining)${NC}"
  else
    echo -e "Remaining: ${RED}OVERTIME by $(fmt_duration $(( -remaining )))${NC}"
  fi
}

# -- paper ----------------------------------------------------

cmd_paper() {
  require_session
  cat "$PAPER"
}

# -- grade ----------------------------------------------------

cmd_grade() {
  require_session
  local now elapsed overtime=0
  now=$(date +%s)
  elapsed=$(( now - START_EPOCH ))
  [[ $now -gt $DEADLINE_EPOCH ]] && overtime=$(( now - DEADLINE_EPOCH ))

  echo -e "${CYAN}+==========================================================+${NC}"
  echo -e "${CYAN}|              CKA Practice Exam - Results                 |${NC}"
  echo -e "${CYAN}+==========================================================+${NC}"
  echo ""

  local earned=0 possible=0 idx=0 dom_rows=""
  for d in $QUESTIONS; do
    idx=$((idx + 1))
    local out line got want
    out=$(bash "$BASE_DIR/$d/validate.bash" 2>/dev/null)
    line=$(echo "$out" | grep -oE "Results: [0-9]+/[0-9]+ passed" | tail -1)

    if [[ -z "$line" ]]; then
      got=0
      want=$(question_weight "$d")
    else
      got=$(echo "$line" | grep -oE "[0-9]+/" | tr -d '/')
      want=$(echo "$line" | grep -oE "/[0-9]+" | tr -d '/')
    fi

    earned=$(( earned + got ))
    possible=$(( possible + want ))

    local colour="$RED"
    [[ "$got" -eq "$want" ]] && colour="$GREEN"
    [[ "$got" -gt 0 && "$got" -lt "$want" ]] && colour="$YELLOW"
    printf "  %2d. %-45s ${colour}%2d/%-2d${NC}\n" "$idx" "$d" "$got" "$want"
    dom_rows+="$(question_domain "$d"):$got:$want"$'\n'
  done

  local pct
  pct=$(python3 -c "print(f'{$earned / max($possible,1) * 100:.1f}')")

  echo ""
  echo "  ----------------------------------------------------------"
  printf "  Score: %d/%d points  =  %s%%   (pass mark %d%%)\n" \
    "$earned" "$possible" "$pct" "$PASS_MARK"
  printf "  Time:  %s of %d:00 minutes\n" "$(fmt_duration $elapsed)" "$LIMIT_MINUTES"

  echo ""
  echo "  By domain (weakest first - drill the bottom of this list):"
  printf '%s' "$dom_rows" | python3 -c '
import sys
weights = dict((w.split(":")[0], float(w.split(":")[1])) for w in sys.argv[1:])
agg = {}
for line in sys.stdin.read().splitlines():
    if not line.strip():
        continue
    dom, got, want = line.rsplit(":", 2)
    a = agg.setdefault(dom, [0, 0])
    a[0] += int(got); a[1] += int(want)
rows = []
for dom, (got, want) in agg.items():
    pct = got / want * 100 if want else 0.0
    rows.append((pct, dom, got, want))
for pct, dom, got, want in sorted(rows):
    bar = "#" * int(round(pct / 5)) + "." * (20 - int(round(pct / 5)))
    flag = "  <- below pass mark" if pct < 66 else ""
    print(f"    {dom:22} {got:3d}/{want:-3d}  {bar}  {pct:5.1f}%{flag}")
' $DOMAIN_WEIGHTS

  if [[ $overtime -gt 0 ]]; then
    echo -e "  ${RED}Finished $(fmt_duration $overtime) OVER the time limit.${NC}"
    echo -e "  ${RED}In a real exam this score would not have been reached.${NC}"
  fi
  echo ""

  local verdict
  verdict=$(python3 -c "print(1 if $pct >= $PASS_MARK else 0)")
  if [[ "$verdict" == "1" && $overtime -eq 0 ]]; then
    echo -e "  ${GREEN}${BOLD}PASS${NC}"
  elif [[ "$verdict" == "1" ]]; then
    echo -e "  ${YELLOW}${BOLD}PASS on points, FAIL on time${NC}"
  else
    echo -e "  ${RED}${BOLD}FAIL${NC}"
  fi
  echo ""
  archive_session "$pct" >/dev/null

  echo "  Review solutions:  cat <question-dir>/SolutionNotes.bash"
  echo "  Tear down:         scripts/exam-mode.sh cleanup"
  echo ""
  echo "  Repeat this exact paper (replays the recorded question list):"
  echo "    scripts/exam-mode.sh cleanup && scripts/exam-mode.sh retake"
  echo "  Same paper, tighter clock:"
  echo "    scripts/exam-mode.sh retake -t $(( LIMIT_MINUTES * 3 / 4 ))"
  echo "  Regenerate from the seed instead (only matches while the labs are unchanged):"
  echo "    $(replay_command "$SEED" "$LIMIT_MINUTES" "$MODE" "$SAFE")"
  echo ""

  [[ "$verdict" == "1" && $overtime -eq 0 ]] && exit 0 || exit 1
}

# -- cleanup --------------------------------------------------

cmd_cleanup() {
  require_session
  echo -e "${CYAN}Tearing down the exam session...${NC}"
  for d in $QUESTIONS; do
    printf "  %-45s " "$d"
    if bash "$BASE_DIR/$d/cleanup.bash" >/dev/null 2>&1; then
      echo -e "${GREEN}done${NC}"
    else
      echo -e "${YELLOW}cleanup reported errors${NC}"
    fi
  done
  archive_session >/dev/null
  rm -f "$SESSION" "$PAPER"
  echo ""
  echo -e "${GREEN}[OK] Exam session cleared.${NC}"
  echo "Recorded for replay - repeat it with: scripts/exam-mode.sh retake"
}

# -- main -----------------------------------------------------

if [[ $# -lt 1 ]]; then
  grep '^#' "$0" | sed -n '2,46p' | sed 's/^# \?//'
  exit 1
fi

CMD="$1"; shift
case "$CMD" in
  start)   cmd_start "$@" ;;
  plan)    cmd_plan "$@" ;;
  retake)  cmd_retake "$@" ;;
  history) cmd_history ;;
  status)  cmd_status ;;
  paper)   cmd_paper ;;
  grade)   cmd_grade ;;
  cleanup) cmd_cleanup ;;
  *) echo "Unknown command: $CMD (expected start|plan|retake|history|status|paper|grade|cleanup)" >&2; exit 1 ;;
esac
