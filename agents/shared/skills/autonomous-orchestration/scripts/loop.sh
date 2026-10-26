#!/bin/bash
# usage: loop.sh TASK WORKTREE_DIR BRANCH [START_ROUND]  -- review/fix until PASS, max 8 rounds
# HARD_TASKS="T3a T13 T15" gets a forced Opus high review at round 2 and an Opus medium fixer after it.
HERE=$(cd "$(dirname "$0")" && pwd)
HARD_TASKS=${HARD_TASKS:-}
TASK=$1; WT=$2; BR=$3; N=${4:-1}
while [ $N -le 8 ]; do
  E=deepseek
  [ $((N%4)) -eq 0 ] && E=opus
  case " $HARD_TASKS " in *" $TASK "*) [ $N -eq 2 ] && E=opus;; esac
  $HERE/run.sh $TASK review $N $WT $BR $E
  F=$WT/$TASK-REVIEW-R$N.md
  if [ -f "$F" ] && grep -q "VERDICT: PASS" "$F"; then
    case " $HARD_TASKS " in *" $TASK "*) if [ $N -eq 1 ]; then N=2; continue; fi;; esac
    echo "PASS at round $N"; exit 0; fi
  FE=deepseek
  case " $HARD_TASKS " in *" $TASK "*) [ "$E" = opus ] && FE=opus-medium;; esac
  $HERE/run.sh $TASK fix $N $WT $BR $FE
  N=$((N+1))
done
echo "NO PASS after 8 rounds"; exit 1
