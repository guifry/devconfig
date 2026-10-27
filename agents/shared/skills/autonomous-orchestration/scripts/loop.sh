#!/bin/bash
# usage: loop.sh TASK WORKTREE_DIR BRANCH [START_ROUND]
# Review/fix until no P0 or P1 remains. No round cap (owner, 27 Oct).
# Opus 5.5 high reviews: every 4th round of any task, and round 2 of the hard tasks (forced even if R1 passed);
# the fix after an Opus review is Opus 5.5 medium.
HERE=$(cd "$(dirname "$0")" && pwd)
HARD=" ${HARD_TASKS:-} "
TASK=$1; WT=$2; BR=$3; N=${4:-1}
while true; do
  E=deepseek
  [ $((N%4)) -eq 0 ] && E=opus
  case "$HARD" in *" $TASK "*) [ $N -eq 2 ] && E=opus;; esac
  $HERE/run.sh $TASK review $N $WT $BR $E
  F=$WT/$TASK-REVIEW-R$N.md
  if [ -f "$F" ] && grep -q "VERDICT: PASS" "$F"; then
    case "$HARD" in *" $TASK "*) if [ $N -eq 1 ]; then N=2; continue; fi;; esac
    echo "PASS at round $N"; exit 0; fi
  FE=deepseek; [ "$E" = opus ] && FE=opus-medium
  $HERE/run.sh $TASK fix $N $WT $BR $FE
  N=$((N+1))
done
