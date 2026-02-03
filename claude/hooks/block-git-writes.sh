#!/bin/bash
# Block GitHub CLI write operations and git push
# Exit code 2 = block the operation
# Exit code 0 = allow the operation

# Read the tool input from stdin (JSON)
INPUT=$(cat)

# Extract the command from the JSON input
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
    exit 0
fi

# Block rm commands (any form)
if echo "$COMMAND" | grep -qE '(^|\s|;|&&|\|\|)rm\s'; then
    echo "BLOCKED: rm command not allowed during autonomous mode" >&2
    exit 2
fi

# Block patterns for GitHub CLI write operations
if echo "$COMMAND" | grep -qE '^\s*gh\s+(pr\s+create|pr\s+merge|pr\s+close|pr\s+edit|pr\s+ready|issue\s+create|issue\s+close|issue\s+edit|release\s+create|repo\s+create|repo\s+delete|repo\s+edit)'; then
    echo "BLOCKED: GitHub CLI write operation not allowed during autonomous mode" >&2
    exit 2
fi

# Block git push (any form)
if echo "$COMMAND" | grep -qE '^\s*git\s+push|&&\s*git\s+push|\|\|\s*git\s+push|;\s*git\s+push'; then
    echo "BLOCKED: git push not allowed during autonomous mode" >&2
    exit 2
fi

# Block gh pr create embedded in pipes or chains
if echo "$COMMAND" | grep -qE 'gh\s+pr\s+create'; then
    echo "BLOCKED: gh pr create not allowed during autonomous mode" >&2
    exit 2
fi

# Allow everything else
exit 0
