---
description: Parallelise a plan into chapters with generated prompts for concurrent execution
argument-hint: [path-to-plan]
---

You are tasked with transforming a sequential plan into a parallelised execution structure.

## Input Resolution

Plan location priority:
1. If `$ARGUMENTS` provided and non-empty: use that path
2. Otherwise: find the most recently modified `.md` file in `~/.claude/plans/`

If no plan found, report error and stop.

## Analysis Process

1. **Read & Parse Plan**: Read the entire plan file. Identify all discrete tasks/steps.

2. **Dependency Analysis**: For each task, determine:
   - Files it will read
   - Files it will modify/create
   - External dependencies (APIs, databases, etc.)
   - Logical dependencies on prior task outputs

3. **Conflict Detection**: Tasks conflict if they:
   - Modify the same file
   - One reads a file another modifies
   - Share logical dependencies (task B needs task A's output)

4. **Chapter Formation**: Group tasks into chapters where:
   - Chapter 0: Initial tasks with no dependencies
   - Chapter N: Tasks that can run in parallel after Chapter N-1 completes
   - Tasks within a chapter have NO conflicts with each other
   - All tasks in Chapter N depend on at least one task from previous chapters

## Output Structure

Create folder: `.claude-parallel-prompts/` in current working directory.

Note: This folder should be added to `.gitignore` - it's temporary working material.

### 1. Create `_plan.md`

```markdown
# Parallelised Plan

Source: [original plan path]
Generated: [timestamp]

## Overview
- Total tasks: X
- Chapters: Y
- Max parallelism: Z (largest chapter)

## Execution Order

### Chapter 0 (Sequential Setup)
- [ ] Task description

### Chapter 1 (Parallel: N tasks)
- [ ] Task A
- [ ] Task B
- [ ] Task C

### Chapter 2 (Sequential Gate)
- [ ] Task that unblocks next parallel batch

[continue pattern...]

## Dependency Graph
[ASCII or text representation showing task dependencies]
```

### 2. Create `state.json`

```json
{
  "chapters": [
    {
      "id": 0,
      "status": "pending",
      "commitHash": null,
      "tasks": [
        {"id": "ch0-task0-setup", "status": "pending"}
      ]
    }
  ]
}
```

Task statuses: `pending` | `in_progress` | `completed` | `failed`
Chapter statuses: `pending` | `in_progress` | `completed` | `blocked`

### 3. Create Prompt Files

For each task, create: `chX-taskY-[short-description].md`

Each prompt file structure:

```markdown
# Context Building

## Project Overview
[Brief description of overall project/goal from original plan]

## Required Reading
Before starting, read and understand these files:
- `path/to/file1` - [why this file matters]
- `path/to/file2` - [what to understand from it]

## Current State
[What has been completed in prior chapters that this task depends on]

## Scope Boundaries
You MUST NOT:
- Edit files outside: [list of allowed files]
- Modify: [specific files other parallel tasks touch]

---

# Task

## Objective
[Clear, specific goal]

## Steps
1. [Specific step]
2. [Specific step]

## Success Criteria
- [ ] [Measurable outcome]
- [ ] [Measurable outcome]

## Files to Modify
- `path/to/file` - [what change]

---

# After Completion

Write a concise report to `.claude-parallel-prompts/[this-file-name].report.md`:
- Files modified (with line refs)
- What was done and why
- Any issues encountered

Keep under 50 lines. This report will be used by the orchestrator to verify your work.
```

## Execution Notes

After generating:
1. Report summary: chapters count, max parallelism, estimated speedup
2. List any tasks that could NOT be parallelised and why
3. Highlight any risky parallel pairs (low confidence in non-conflict)

## Edge Cases

- Single-task chapters are fine (gates between parallel batches)
- If entire plan is sequential (all conflicts), create single-task chapters with explanation
- If plan is ambiguous, ask clarifying questions before generating

## Post-Generation Actions

1. Add `.claude-parallel-prompts/` to `.gitignore` if not already present
2. Print execution instructions: how to run parallel tasks using multiple terminal sessions
3. Mention that user should review prompts before spawning agents
