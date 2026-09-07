#!/usr/bin/env bash
# Claude Code PreToolUse adapter for the shared destructive-command guard.
#
# Always on, unlike block-git-writes.sh which is opt-in for autonomous runs.
# Exit 2 blocks the call and is honoured in bypassPermissions mode, so this
# still applies under `claude --dangerously-skip-permissions`.
#
# Deliberately NOT using permissionDecision:"ask" — whether a hook-originated
# ask surfaces a prompt under bypassPermissions is undocumented, and a guard
# that silently degrades to allow is worse than none. The escape hatch is
# `guard-off` (see agents/shared/guard/check-command.sh).

GUARD="$HOME/projects/devconfig/agents/shared/guard/check-command.sh"
[[ -x $GUARD ]] || exit 0

INPUT=$(cat)
COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[[ -n $COMMAND ]] || exit 0

if REASON=$("$GUARD" "$COMMAND"); then
    exit 0
fi

printf 'BLOCKED by devconfig guard: %s\n' "$REASON" >&2
printf 'Command: %s\n' "$COMMAND" >&2
printf 'If this is genuinely intended, run it yourself, or `guard off` to disarm for 15 min.\n' >&2
exit 2
