# Review Protocol

This document defines the review contract. It is read by:
- The **worker agent** (to understand what reviewers will judge)
- The **review_loop.py script** (to build the reviewer's prompt)

---

## Reviewer prompt template

The reviewer receives exactly this, nothing more:

```
You are reviewing code changes for a task. You have no prior context — you are seeing this code for the first time.

## Task specification
{task_spec}

## Changed files (diff)
{diff}

## Repository path
{repo_path}

## Instructions

1. Read the diff carefully.
2. If you need to understand surrounding code, read files from the repository path.
3. Evaluate the changes against the criteria below.
4. Produce a review as a list of items, each tagged [BLOCKING] or [NON-BLOCKING].

## Review criteria

Flag as [BLOCKING]:
- Bugs: logic errors, off-by-one, null/undefined access, race conditions
- Missed edge cases: unhappy paths not handled, boundary conditions ignored
- Blind spots: aspects of the task that were not addressed at all
- Regressions: changes that break existing behaviour
- Security: injection, XSS, exposed secrets, auth bypass
- Incorrect fix: change doesn't actually solve the stated problem
- Data loss risk: state mutation without rollback, destructive operations without guards
- Badly broken code: unreadable, unmaintainable, fundamentally wrong approach

Flag as [NON-BLOCKING]:
- Style preferences: naming, formatting beyond linter rules
- Optional improvements: "could also do X" suggestions
- Over-engineering suggestions: abstractions, generalisations, future-proofing
- Minor refactors that don't affect correctness
- Comments/documentation suggestions
- Alternative approaches that aren't clearly better

## Output format

For each item:
```
[BLOCKING] or [NON-BLOCKING] — file:line — description
Reasoning: one sentence explaining why this matters (or doesn't)
```

If no issues found, output: "No issues found. Changes look correct."
```

---

## Worker assessment rules

When the worker (original agent) receives a review:

1. Read each item with full conversation context
2. For [BLOCKING] items:
   - If valid: fix it
   - If based on reviewer's lack of context (reviewer didn't know about a constraint, earlier decision, or requirement): dismiss with a one-line note explaining why
3. For [NON-BLOCKING] items: ignore. Do not address them. Move on.
4. After fixing all valid blocking items, decide:
   - Were the fixes substantial (changed logic, added handling, fixed a real bug)? → request another review cycle
   - Were the fixes minor (variable rename, small guard clause)? → done, move on
5. Hard cap: 2 review cycles. After cycle 2, move on regardless.

---

## Termination

The review loop stops when ANY of these is true:
- The worker determines all remaining feedback is non-blocking or dismissed
- The worker's fixes were minor enough to not warrant re-review
- 2 review cycles have been completed
