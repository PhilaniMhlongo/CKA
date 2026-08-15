#!/bin/bash
# ============================================================
# exam-mode.sh - timed, weighted, multi-question exam simulation
#
# Runs a random set of questions as ONE scored session against the
# clock, the way killer.sh / the real CKA works - rather than one
# isolated lab at a time.
#
# Usage:
#   scripts/exam-mode.sh start [-n 20] [-t 120] [-s SEED] [--safe]
#   scripts/exam-mode.sh start --questions "5 13 56 66"
#   scripts/exam-mode.sh status      # time remaining
#   scripts/exam-mode.sh paper       # reprint the question paper
#   scripts/exam-mode.sh grade       # weighted score + pass/fail
#   scripts/exam-mode.sh cleanup     # tear down the whole session
#
# Scoring: each question is worth points equal to the number of checks
# in its validate.bash, so bigger tasks are worth more. Pass mark is 66%,
# matching the real CKA.
# ============================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

STATE_DIR="${CKA_EXAM_HOME:-$HOME/.cka-exam}"
SESSION="$STATE_DIR/session.env"
PAPER="$STATE_DIR/exam-paper.txt"

DEFAULT_COUNT=20
DEFAULT_MINUTES=120
PASS_MARK=66

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
}

fmt_duration() {
  local total=$1 sign=""
  if [[ $total -lt 0 ]]; then sign="-"; total=$(( -total )); fi
  printf "%s%d:%02d:%02d" "$sign" $((total/3600)) $(((total%3600)/60)) $((total%60))
}

# -- start ----------------------------------------------------

cmd_start() {
  local count=$DEFAULT_COUNT
  local minutes=$DEFAULT_MINUTES
  local seed=$RANDOM
  local safe=0
  local explicit=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n) count="$2"; shift 2 ;;
      -t) minutes="$2"; shift 2 ;;
      -s) seed="$2"; shift 2 ;;
      --safe) safe=1; shift ;;
      --questions) explicit="$2"; shift 2 ;;
      *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
  done

  if [[ -f "$SESSION" ]]; then
    echo -e "${YELLOW}An exam session already exists.${NC}"
    echo "Grade it with 'scripts/exam-mode.sh grade' or discard it with"
    echo "'scripts/exam-mode.sh cleanup' before starting a new one."
    exit 1
  fi

  mkdir -p "$STATE_DIR"

  local selected=""
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
    local candidates
    candidates=$(all_question_dirs)
    if [[ $safe -eq 1 ]]; then
      local filtered=""
      while read -r d; do
        [[ -z "$d" ]] && continue
        needs_special_cluster "$d" || filtered+="$d"$'\n'
      done <<< "$candidates"
      candidates=$(echo "$filtered" | grep -v '^$')
    fi
    # shellcheck disable=SC2086
    selected=$(python3 -c '
import random, sys
seed, n = sys.argv[1], int(sys.argv[2])
items = [i for i in sys.argv[3:] if i]
random.seed(seed)
picked = random.sample(items, min(n, len(items)))
print("\n".join(sorted(picked, key=lambda d: int(d.split("-")[1]))))
' "$seed" "$count" $candidates)
  fi

  local n_selected
  n_selected=$(echo "$selected" | grep -c .)

  # -- compute weights and build the paper --------------------
  local total_weight=0
  while read -r d; do
    [[ -z "$d" ]] && continue
    total_weight=$(( total_weight + $(question_weight "$d") ))
  done <<< "$selected"

  local start_epoch deadline_epoch
  start_epoch=$(date +%s)
  deadline_epoch=$(( start_epoch + minutes * 60 ))

  {
    echo "============================================================"
    echo " CKA PRACTICE EXAM"
    echo "============================================================"
    echo " Questions:  $n_selected"
    echo " Time limit: ${minutes} minutes"
    echo " Pass mark:  ${PASS_MARK}%"
    echo " Seed:       $seed   (reuse with -s $seed for the same paper)"
    echo " Deadline:   $(date -d "@$deadline_epoch" '+%Y-%m-%d %H:%M:%S')"
    echo "============================================================"
    echo ""
    local idx=0
    while read -r d; do
      [[ -z "$d" ]] && continue
      idx=$((idx + 1))
      local w pct
      w=$(question_weight "$d")
      pct=$(python3 -c "print(f'{$w / $total_weight * 100:.1f}')")
      echo "------------------------------------------------------------"
      echo "QUESTION $idx of $n_selected   [$d]   Weight: ${pct}%"
      echo "------------------------------------------------------------"
      cat "$BASE_DIR/$d/Questions.bash"
      echo ""
    done <<< "$selected"
  } > "$PAPER"

  # -- persist the session ------------------------------------
  {
    echo "SEED=$seed"
    echo "START_EPOCH=$start_epoch"
    echo "DEADLINE_EPOCH=$deadline_epoch"
    echo "LIMIT_MINUTES=$minutes"
    echo "TOTAL_WEIGHT=$total_weight"
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
  echo -e "${YELLOW}Note:${NC} all labs share one cluster. Node-level questions"
  echo "(drain, kubelet, etcd, upgrade) can disturb their neighbours."
  echo "Use --safe for a clean scored run on a single-node cluster."
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

  local earned=0 possible=0 idx=0
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
  done

  local pct
  pct=$(python3 -c "print(f'{$earned / max($possible,1) * 100:.1f}')")

  echo ""
  echo "  ----------------------------------------------------------"
  printf "  Score: %d/%d points  =  %s%%   (pass mark %d%%)\n" \
    "$earned" "$possible" "$pct" "$PASS_MARK"
  printf "  Time:  %s of %d:00 minutes\n" "$(fmt_duration $elapsed)" "$LIMIT_MINUTES"

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
  echo "  Review solutions:  cat <question-dir>/SolutionNotes.bash"
  echo "  Tear down:         scripts/exam-mode.sh cleanup"
  echo "  Same paper again:  scripts/exam-mode.sh start -s $SEED"
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
  rm -f "$SESSION" "$PAPER"
  echo ""
  echo -e "${GREEN}[OK] Exam session cleared.${NC}"
}

# -- main -----------------------------------------------------

if [[ $# -lt 1 ]]; then
  grep '^#' "$0" | sed -n '2,28p' | sed 's/^# \?//'
  exit 1
fi

CMD="$1"; shift
case "$CMD" in
  start)   cmd_start "$@" ;;
  status)  cmd_status ;;
  paper)   cmd_paper ;;
  grade)   cmd_grade ;;
  cleanup) cmd_cleanup ;;
  *) echo "Unknown command: $CMD (expected start|status|paper|grade|cleanup)" >&2; exit 1 ;;
esac
