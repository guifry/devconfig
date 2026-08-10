---
name: ralph-launch
description: Generate PROMPT.md and start the autonomous ralph loop
allowed-tools: Bash, Read, Write, Grep, Glob
---

# Ralph Launch — Generate PROMPT.md + Start Loop

## Pre-flight Checks

1. `PRD.json` exists in current directory
2. Git working tree is clean (`git status --porcelain` is empty)
3. At least one story has status `pending`
4. `rx` is in PATH

If any check fails, report and stop.

## Generate PROMPT.md

Write `PROMPT.md` in current directory:

```markdown
You are an autonomous coding agent executing one story from PRD.json.

## Rules
- Read PRD.json first
- Pick the next eligible story: status=pending, all depends_on are done
- If no eligible story, print "ALL_DONE" and exit
- Implement the story completely:
  - Write/modify source code
  - Write/update tests
  - Run tests — fix until passing
  - Run linter/formatter if configured
- Update PRD.json: set story status to "done"
- If you cannot complete the story after 3 attempts, set status to "failed" and exit
- Stage changes with `git add -u` plus any new files you created (explicit paths, never `git add -A`)
- Commit with a concise message referencing the story: "story-{id}: {title}"
- Do NOT push. Do NOT create PRs.
- Exit after one story. The external loop will spawn a new session for the next one.

## Current State
Read PRD.json to determine which story to work on.
```

## Initialise progress.txt

Write `progress.txt`:
```
ralph loop initialised
stories: {total} total, {pending} pending
---
```

## Confirm + Launch

Show the user:
- Number of pending stories
- The generated PROMPT.md content
- The command that will run: `rx`

Ask for confirmation. On confirm, run `rx`.
