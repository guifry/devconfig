#!/bin/bash
# usage: loop.sh TASK WORKTREE_DIR BRANCH [START_ROUND]
# Max 3 rounds: R1 full review, R2 full review (Opus on hard tasks), R3 narrow verification.
# After R3 an unfixed P0 stops the loop (orchestrator decides); leftover P1s are deferred to the register.
HERE=$(cd "$(dirname "$0")" && pwd)
HARD=" ${HARD_TASKS:-} "
TASK=$1; WT=$2; BR=$3; N=${4:-1}
while [ $N -le 3 ]; do
  E=deepseek; KIND=full
  case "$HARD" in *" $TASK "*) [ $N -eq 2 ] && E=opus;; esac
  [ $N -eq 3 ] && KIND=followup
  REVIEW_KIND=$KIND $HERE/run.sh $TASK review $N $WT $BR $E
  F=$WT/$TASK-REVIEW-R$N.md
  if [ -f "$F" ] && grep -q "VERDICT: PASS" "$F"; then
    case "$HARD" in *" $TASK "*) if [ $N -eq 1 ]; then N=2; continue; fi;; esac
    echo "PASS at round $N"; exit 0; fi
  [ $N -eq 3 ] && { echo "FAIL at round 3: orchestrator decides (P0 blocks, P1 to register)"; exit 1; }
  FE=deepseek; [ "$E" = opus ] && FE=opus-medium
  $HERE/run.sh $TASK fix $N $WT $BR $FE
  N=$((N+1))
done
