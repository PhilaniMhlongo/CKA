#!/usr/bin/env bash
# Simple countdown timer. usage: ./timer.sh [minutes]
MINS="${1:-60}"
END=$(( $(date +%s) + MINS*60 ))
trap 'echo; echo "timer stopped."; exit 0' INT
while :; do
  LEFT=$(( END - $(date +%s) ))
  if [ "$LEFT" -le 0 ]; then
    printf "\r\033[0;31m  TIME IS UP — stop typing and run grade.sh          \033[0m\n"
    for _ in 1 2 3; do printf '\a'; sleep 1; done
    exit 0
  fi
  if [ "$LEFT" -le 300 ]; then C='\033[0;31m'; elif [ "$LEFT" -le 900 ]; then C='\033[1;33m'; else C='\033[0;32m'; fi
  printf "\r${C}  time remaining  %02d:%02d  \033[0m" $((LEFT/60)) $((LEFT%60))
  sleep 1
done
