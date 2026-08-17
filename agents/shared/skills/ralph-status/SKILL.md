---
name: ralph-status
description: Show progress of the autonomous ralph loop
allowed-tools: Bash, Read, Grep, Glob
---

# Ralph Status — Progress Report

## Data Sources

1. **PRD.json** — story statuses
2. **progress.txt** — iteration log
3. **git log** — commits made by the loop

## Report

### Story Table

Read PRD.json and display:

```
ID | Title                  | Status    | Depends On
1  | Add user model         | done      | -
2  | Add user repository    | done      | 1
3  | Add user routes        | failed    | 2
4  | Add user tests         | pending   | 3
```

### Summary Stats

- Total: X stories
- Done: X
- Failed: X
- Pending: X
- In Progress: X

### Commits

```bash
git log --oneline --since="$(head -1 progress.txt | grep -oP '\d{4}-.*')" 2>/dev/null || git log --oneline -20
```

### Blockers

Identify:
- Failed stories blocking pending ones (via depends_on)
- Stories stuck in_progress (possible crash)

### Recommendation

Based on state, suggest:
- If all done: "Run `/ralph-review` to review and prepare PR"
- If failed stories: "Story {id} failed — review and fix manually, then re-run `/ralph-launch`"
- If in progress: "Loop may still be running — check `progress.txt` tail"
- If pending with no blockers: "Run `/ralph-launch` to continue"
