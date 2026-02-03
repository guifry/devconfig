---
name: ralph-plan
description: Decompose a feature into atomic stories for autonomous execution
allowed-tools: Bash, Read, Grep, Glob, Write, Task
---

# Ralph Plan — Create PRD.json

Decompose the user's feature request into a PRD (Product Requirements Document) of atomic, independently implementable stories.

## Steps

### 1. Gather Context

Read the codebase to understand:
- Project structure and architecture
- Existing patterns, conventions, test setup
- CLAUDE.md / project-level instructions
- Related existing code

### 2. Clarify Scope

Ask the user:
- What's the feature? (if not already clear)
- Any constraints or preferences?
- Which files/modules are in scope?

### 3. Decompose into Stories

Break the feature into atomic stories. Each story must be:
- **Independently committable** — passes tests on its own
- **Small** — one logical change, ideally <200 lines diff
- **Ordered** — respects dependencies between stories
- **Minimal dependencies** — only add `depends_on` when there is a genuine code or data dependency (story B modifies files created by story A, or story B's implementation requires story A's output). Stories that touch unrelated files should have `depends_on: []` even if they come later in the list. This enables parallel execution.
- **Testable** — has clear acceptance criteria

Target: 5-15 stories. If >15, the feature is too large — suggest splitting.

### 4. Write PRD.json

Write to `PRD.json` in the current directory:

```json
{
  "feature": "Feature name",
  "description": "One-line description",
  "created": "ISO timestamp",
  "stories": [
    {
      "id": 1,
      "title": "Short imperative title",
      "description": "What to implement",
      "status": "pending",
      "depends_on": [],
      "files": ["path/to/file.py"],
      "acceptance_criteria": [
        "Criterion 1",
        "Criterion 2"
      ],
      "tests": "Description of tests to write or update"
    }
  ]
}
```

### Story Statuses
- `pending` — not started
- `in_progress` — being worked on
- `done` — implemented and committed
- `failed` — attempted but failed (needs human review)
- `skipped` — intentionally skipped

### 5. Validate

- No circular dependencies
- Every story has at least one acceptance criterion
- File paths exist (or are clearly new files)
- Stories are ordered so depends_on references earlier IDs only

### 6. Report

Print a summary table:
```
ID | Title                  | Depends On | Files
1  | Add user model         | -          | models/user.py
2  | Add user repository    | 1          | repos/user.py
...
```

Confirm with user before finalising.
