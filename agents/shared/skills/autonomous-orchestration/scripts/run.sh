#!/bin/bash
# usage: run.sh TASK ROLE(review|fix) ROUND WORKTREE_DIR BRANCH [deepseek|opus|opus-medium]
# Templates REVIEW-template.md / FIX-template.md in $PROMPTS use the tokens TASK, ROUND, BRANCH.
PROMPTS=${PROMPTS:?set PROMPTS to the folder holding the templates}
OPUS_MODEL=${OPUS_MODEL:-claude-opus-5-5}
DEEPSEEK_MODEL=${DEEPSEEK_MODEL:-deepseek/deepseek-flash}
TASK=$1; ROLE=$2; ROUND=$3; WT=$4; BR=$5; ENGINE=${6:-deepseek}
T=$PROMPTS/$( [ "$ROLE" = review ] && echo REVIEW || echo FIX )-template.md
[ "$ROLE" = review ] && [ "$REVIEW_KIND" = followup ] && T=$PROMPTS/REVIEW-followup-template.md
P=$(sed -e "s/TASK/$TASK/g" -e "s/ROUND/$ROUND/g" -e "s#BRANCH#$BR#g" "$T")
cd "$WT" || exit 1
if [ "$ENGINE" = opus ] || [ "$ENGINE" = opus-medium ]; then
  EFF=high; [ "$ENGINE" = opus-medium ] && EFF=medium
  claude -p --dangerously-skip-permissions --model "$OPUS_MODEL" --effort $EFF "$P" > "$WT.$TASK-$ROLE-r$ROUND.log" 2>&1
else
  opencode run --model "$DEEPSEEK_MODEL" --auto --title "$TASK $ROLE r$ROUND" "$P" > "$WT.$TASK-$ROLE-r$ROUND.log" 2>&1
fi
echo "exit $?"; git log --oneline -3
