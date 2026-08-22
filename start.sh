#!/usr/bin/env bash
# Start the clock on an exam set and print the paper.
set -u
SET="${1:-}"
case "$SET" in
  1|01) DIR=set-01 ;;
  2|02) DIR=set-02 ;;
  3|03) DIR=set-03 ;;
  *) echo "usage: ./start.sh <1|2|3>"; exit 1 ;;
esac
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT" || exit 1

if [ -x "$DIR/setup.sh" ]; then
  echo ">> seeding pre-broken resources for this set..."
  "./$DIR/setup.sh"
fi

date +%s > "$DIR/.started"
echo
echo "==================================================================="
echo "  $DIR started at $(date '+%H:%M:%S')  —  you have 60 minutes"
echo "  Deadline: $(date -d '+60 minutes' '+%H:%M:%S' 2>/dev/null || date -v+60M '+%H:%M:%S')"
echo "==================================================================="
echo
echo "  Paper : $ROOT/$DIR/questions.md"
echo "  Timer : ./timer.sh 60      (run in a second terminal tab)"
echo "  Mark  : ./$DIR/grade.sh"
echo
echo "Opening the paper with less — press q to quit, then get to work."
sleep 2
less "$DIR/questions.md"
