---
name: batch-execute
description: Autonomous batch execution of a list of tasks with triage, parallel execution, and review loops. Takes a document or inline list, classifies work by complexity, plans appropriately, executes in parallel where safe, and self-reviews.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, TaskCreate, TaskUpdate, Skill
argument-hint: <path to task list document or inline task description>
user-invocable: true
---

# Batch Execute

Autonomous execution of a batch of tasks. You receive a list of work items (bugs, features, chores) and execute them end-to-end with appropriate rigour per item.

## Constraints

- **LOCAL ONLY.** No git push, no deploys, no remote migrations, no staging/production mutations. Read-only remote access (git fetch, API reads) is fine.
- All work happens on local branches and worktrees.
- You may run local dev servers, tests, linters, type-checkers.

---

## Phase 1 — Intake

Read the task list document (PDF, markdown, plain text, or inline).

For each item, extract:
- **What**: one-line summary of the work
- **Where**: screenshot context, page/component mentioned, or area of codebase
- **Acceptance criteria**: what "done" looks like (infer from description if not explicit)

If anything is ambiguous, list your assumptions. Do not ask the user for clarification on every item — use judgement. Flag genuinely unclear items at the end.

---

## Phase 2 — Triage

Classify each item into a tier. This determines the entire downstream pipeline.

### Tier 1 — Trivial (batch, no review)

Work where the fix is obvious from the description alone and risk of regression is near zero.

Examples across domains:
- Styling/cosmetic: padding, colour, font size, spacing
- Copy/text changes: labels, error messages, placeholder text
- Simple config: feature flag, env var, constant
- One-line obvious fixes: typo in variable name, missing null check with clear pattern

Execution: batch all T1 items, execute sequentially (fast), one commit. No planning. No review loop.

### Tier 2 — Standard (plan, review if non-trivial)

Work where the fix requires understanding surrounding code but the scope is contained.

Examples:
- Bug fixes with clear reproduction steps
- State management issues
- Component rewiring, prop threading
- API response handling fixes
- Data transformation bugs
- Anything touching shared utilities or >1 file

Execution: light exploration, brief plan, execute individually. Review loop triggered if the change touches logic (not just wiring) or spans >2 files. Individual commits.

### Tier 3 — Complex (full pipeline)

Work that looks like a bug but is actually feature work, or is genuinely complex.

Examples:
- New behaviour or missing functionality
- Architectural changes disguised as fixes
- Changes spanning multiple bounded contexts
- Performance investigations (profiling needed)
- Anything where the right fix isn't obvious without exploration

Execution: deep exploration, full plan with blind spot analysis, execute in worktree, mandatory review loop, separate branch.

### Triage output

Present the triage table to the user for approval before proceeding:

```
| # | Summary | Tier | Review? | Parallel group | Notes |
```

Parallel group: items that touch independent files/components and can safely run concurrently. Items sharing files go in the same sequential group.

**Wait for user approval before Phase 3.**

---

## Phase 3 — Planning

Depth varies by tier.

### T1 items
No planning. Proceed directly to execution.

### T2 items
For each item:
1. Read affected files
2. Identify the fix
3. List files to change
4. Note any shared dependencies

### T3 items
For each item:
1. Deep exploration — read all related files, trace call chains, understand state flow
2. Draft implementation plan
3. Run `/blindspots` against the plan
4. Revise plan based on blind spots
5. Identify edge cases and unhappy paths
6. List files to change with expected modifications

### Dependency graph
After individual planning, produce a dependency graph:
- Which items touch the same files?
- Which items must be sequential?
- Which can be parallelised in separate worktrees?

---

## Phase 4 — Execution

### T1 batch
Execute all T1 items sequentially in the current branch. Fast, no ceremony. Stage and commit together: `fix: batch trivial fixes (items #X, #Y, #Z)`.

### T2/T3 items — parallel groups
For each parallel group:
- Independent items: spawn subagents with `isolation: "worktree"`, one per item
- Dependent items within a group: execute sequentially within one worktree

Each subagent receives:
- The task spec (description + acceptance criteria)
- The implementation plan (from Phase 3)
- The list of files to modify
- Instruction to commit with a descriptive message on completion

### Mid-execution re-triage
If an agent discovers a T1 item is actually T2/T3 complexity, it stops and reports back. The orchestrator re-triages and routes through the appropriate pipeline. Agents may escalate upward, never downward.

---

## Phase 5 — Smoke test + Review

### Smoke test gate
Before any review, run applicable checks on changed files:
- TypeScript: `tsc --noEmit`
- Linting: `eslint` / `ruff` / project linter
- Tests: run affected test suites if identifiable

If smoke test fails, fix first. Do not waste a review cycle on code that doesn't build.

### Review loop (T2 with logic changes + all T3)

Read `review-protocol.md` in this skill directory for the full review protocol.

Run the review loop script:
```bash
python3 .claude/skills/batch-execute/scripts/review_loop.py \
  --repo-path "$(pwd)" \
  --task-spec "<path to task spec temp file>" \
  --diff "<path to diff file>" \
  --max-cycles 2
```

The script:
1. Spawns a fresh reviewer agent (no conversation context) with the task spec, diff, and repo path
2. Returns the review to this agent (the worker)
3. This agent (the worker) reads the review with full conversation context and decides:
   - Which items are valid and need fixing
   - Which items are based on the reviewer's lack of context and can be dismissed
   - Which items are minor/optional and not worth addressing now
4. If there are valid blocking issues: fix them, then signal the script for another cycle
5. If all remaining feedback is minor/optional/dismissed: done
6. Hard cap: 2 review cycles maximum, then move on regardless

### No review (T1 + T2 without logic changes)
Skip review. Trust the smoke test.

---

## Phase 6 — Merge and verify

1. Merge worktree branches sequentially into the working branch
2. After each merge, run smoke test (type-check + lint)
3. If merge conflict: spawn a resolution agent that sees both branches + conflict markers
4. If resolution fails: flag for user and continue with other branches
5. Run full smoke test on final merged state

---

## Phase 7 — Report

Produce a summary:

```
## Run report

### Completed
| # | Summary | Tier | Review cycles | Status |

### Needs attention
- Items that were re-triaged
- Merge conflicts that couldn't be auto-resolved
- Items flagged for visual/manual verification

### Commits
- list of commits created

### Verify manually
- Items that need visual verification (layout, performance, etc.)
```

---

## Notes

- This skill is domain-agnostic. It works for frontend, backend, infra, docs — any list of tasks.
- The triage criteria above are guidelines, not rules. Use judgement. A "simple CSS fix" that affects a shared design system component is T2, not T1.
- When in doubt, triage up (T1 → T2, T2 → T3). The cost of over-planning is low; the cost of under-planning is rework.
- The user approved the triage in Phase 2. Do not re-ask for approval at later phases unless something fundamentally changed (e.g., a T1 that's actually T3).
