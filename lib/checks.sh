#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Shared check helpers for the CKA practice graders.
# Sourced by set-XX/grade.sh — not meant to be run directly.
# ---------------------------------------------------------------------------

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
BLUE='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

TOTAL_SCORE=0
TOTAL_WEIGHT=0
SUMMARY=()

QNUM=""; QDESC=""; QWEIGHT=0; QPASS=0; QTOTAL=0

# ---------------------------------------------------------------- primitives
ok()  { QPASS=$((QPASS+1)); QTOTAL=$((QTOTAL+1)); printf "  ${GREEN}PASS${NC}  %b\n" "$1"; }
no()  { QTOTAL=$((QTOTAL+1));                     printf "  ${RED}FAIL${NC}  %b\n" "$1"; }

# q <number> <weight%> <short description>
q() {
  _finish_q
  QNUM="$1"; QWEIGHT="$2"; QDESC="$3"; QPASS=0; QTOTAL=0
  printf "\n${BOLD}${BLUE}Question %s${NC} ${DIM}(%s%%)${NC} — %s\n" "$QNUM" "$QWEIGHT" "$QDESC"
}

_finish_q() {
  [ -z "$QNUM" ] && return 0
  local earned pct colour
  if [ "$QTOTAL" -eq 0 ]; then earned=0; pct=0
  else
    earned=$(awk -v w="$QWEIGHT" -v p="$QPASS" -v t="$QTOTAL" 'BEGIN{printf "%.2f", w*p/t}')
    pct=$(( QPASS * 100 / QTOTAL ))
  fi
  TOTAL_SCORE=$(awk -v a="$TOTAL_SCORE" -v b="$earned" 'BEGIN{printf "%.2f", a+b}')
  TOTAL_WEIGHT=$(( TOTAL_WEIGHT + QWEIGHT ))
  if   [ "$pct" -eq 100 ]; then colour="$GREEN"
  elif [ "$pct" -ge 50  ]; then colour="$YELLOW"
  else                         colour="$RED"; fi
  SUMMARY+=("$(printf "  Q%-3s ${colour}%3s%%${NC}  %5s / %-3s pts   %s" \
              "$QNUM" "$pct" "$earned" "$QWEIGHT" "$QDESC")")
  printf "  ${DIM}-> %s/%s checks, %s of %s points${NC}\n" "$QPASS" "$QTOTAL" "$earned" "$QWEIGHT"
  QNUM=""
}

# ------------------------------------------------------------------ checkers
# exists <desc> <kubectl get args...>
exists() { local d="$1"; shift
  if kubectl get "$@" >/dev/null 2>&1; then ok "$d"; else no "$d  ${DIM}(not found)${NC}"; fi; }

# expect <desc> <expected> <kubectl args...>   — exact match on stdout
expect() { local d="$1" want="$2"; shift 2; local got
  got="$(kubectl "$@" 2>/dev/null)"
  if [ "$got" = "$want" ]; then ok "$d"
  else no "$d  ${DIM}(got '${got:-<empty>}', want '$want')${NC}"; fi; }

# contains <desc> <substring> <kubectl args...>
contains() { local d="$1" want="$2"; shift 2; local got
  got="$(kubectl "$@" 2>/dev/null)"
  if printf '%s' "$got" | grep -qF -- "$want"; then ok "$d"
  else no "$d  ${DIM}('$want' not in '${got:-<empty>}')${NC}"; fi; }

# shell <desc> <shell command string>  — passes if exit code is 0
shell() { local d="$1" cmd="$2"
  if bash -c "$cmd" >/dev/null 2>&1; then ok "$d"; else no "$d"; fi; }

# note <text> — informational only, not scored
note() { printf "  ${DIM}note  %s${NC}\n" "$1"; }

# ------------------------------------------------------------------- report
report() {
  _finish_q
  local pct
  pct=$(awk -v s="$TOTAL_SCORE" -v w="$TOTAL_WEIGHT" 'BEGIN{printf "%.1f", (w>0)? s*100/w : 0}')

  printf "\n${BOLD}================== RESULTS ==================${NC}\n"
  local line; for line in "${SUMMARY[@]}"; do printf "%b\n" "$line"; done
  printf "${BOLD}--------------------------------------------${NC}\n"

  if [ -n "${EXAM_ELAPSED:-}" ]; then
    printf "  Time taken : %s\n" "$EXAM_ELAPSED"
  fi
  printf "  Score      : ${BOLD}%s / %s  (%s%%)${NC}\n" "$TOTAL_SCORE" "$TOTAL_WEIGHT" "$pct"

  if awk -v p="$pct" 'BEGIN{exit !(p>=66)}'; then
    printf "  Result     : ${GREEN}${BOLD}PASS${NC}  (cut score 66%%)\n"
  else
    printf "  Result     : ${RED}${BOLD}FAIL${NC}  (cut score 66%%)\n"
  fi
  printf "${BOLD}============================================${NC}\n\n"
  printf "${DIM}Review the FAIL lines above, then check the model answers in solutions/.${NC}\n\n"
}

# ------------------------------------------------------------------ preamble
preamble() {
  local set_name="$1" set_dir="$2"
  if ! command -v kubectl >/dev/null 2>&1; then
    echo "kubectl not found — are you on the Killercoda playground?" >&2; exit 1
  fi
  if ! kubectl get nodes >/dev/null 2>&1; then
    echo "Cannot reach the cluster. Check your kubeconfig." >&2; exit 1
  fi
  if [ -f "$set_dir/.started" ]; then
    local start now diff
    start=$(cat "$set_dir/.started"); now=$(date +%s); diff=$((now-start))
    EXAM_ELAPSED=$(printf "%02d:%02d:%02d" $((diff/3600)) $(((diff%3600)/60)) $((diff%60)))
  fi
  printf "\n${BOLD}%s — automatic marker${NC}\n" "$set_name"
  printf "${DIM}cluster: %s nodes | %s${NC}\n" \
    "$(kubectl get nodes --no-headers 2>/dev/null | wc -l)" "$(date '+%F %T')"
}
