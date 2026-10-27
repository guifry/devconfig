You review the plan reviews of task TASK (a review of the reviews) before the planner amends the plan. Fully autonomous: never ask questions. Read <build>/BUILDING_WELL.md, the plan <build>/TASK-PLAN.md (including its Delete list), the three reviews <build>/TASK-PLAN-REVIEW-A.md, -B.md, -C.md, the spec sections they cite, and the code they point at in <integration worktree> and the T13/T14 worktrees beside it.
For every finding, and for every item in the plan's Delete list, decide KEEP, CHANGE or REJECT, with evidence:
- Deletions and replacements: is the code really unused or duplicated? Search every caller, including other tasks' plans in <build>/, migrations and stored data, public API routes, the workbook, the frontend, tests that guard accounting invariants. Reject a deletion of anything still needed, of stored data or migrations, or of an invariant guard; say what must stay.
- Correctness: is the finding true (recheck figures and code claims)? Reject false ones.
- Conflicts: where two reviewers or a reviewer and the spec disagree, rule which wins and why.
- Scope: reject findings that add a side quest or a rare edge case beyond the spec, unless they protect money or identity.
- Missing: anything all three reviewers missed that would break other tasks.
Write <build>/TASK-PLAN-META-REVIEW.md: a table (finding id, decision, reason) and a section 'Instructions to the planner' that the amendment must follow. Do not edit the plan.
