---
description: Review all changes on current branch against coding standards and test coverage
---

// turbo
0. Run `/rm` workflow first.

# Review Current Branch

## CRITICAL: Scope of Review

**ONLY review and fix code that was changed in this branch (appears in the diff).**

- Do NOT refactor pre-existing code that wasn't modified in this branch
- Do NOT fix violations in code that existed before this branch
- Only flag/fix issues in lines that appear in the diff (+ lines)
- Pre-existing violations should be noted but NOT fixed

When fixing issues:
1. Check if the problematic code is NEW (added in this branch) or PRE-EXISTING
2. If pre-existing: report as "pre-existing issue, out of scope for this branch"
3. If new: fix it

## 1. Identify the base branch and gather diffs

```bash
# Get current branch name
git branch --show-current

# Get the previous branch in the stack
BASE=$(.cascade-notes/scripts/get_previous_branch.sh)
echo "Base branch: $BASE"

# Show all commits on this branch
git log --oneline ${BASE}..HEAD
```

## 2. Gather all changed files

```bash
BASE=$(.cascade-notes/scripts/get_previous_branch.sh)

# List all files changed (including uncommitted)
git diff --name-only $BASE

# Get full diff for review (including uncommitted)
git diff $BASE
```

## 3. Review against coding standards

Read the coding rules and check the diff against them:
- `.windsurf/rules/coding-rules.md` - Security, architecture, code style rules
- `.cascade-notes/testing-rule.md` - Testing patterns

**Key checks:**
- No `mti_organization_id` exposed in API responses
- Composition over inheritance (factory functions, not subclasses)
- `@property` for boolean checks
- Logger at module level, not class field
- **CRITICAL: All imports at file top** - never inside functions/methods. Only exception: circular imports, which MUST have a documenting comment explaining why
- `{Entity}Db` naming pattern for ORM models
- `utc_now_tz_unaware()` instead of `datetime.now()`

**Import check command:**
```bash
# Find any inline imports in changed files
git diff $BASE --name-only -- "*.py" | xargs -I {} grep -n "^    from \|^        from " {} 2>/dev/null
```

## 4. Analyze test coverage impact

For each changed file, determine required test updates:

| Source File Pattern | Required Tests |
|---------------------|----------------|
| `domain/models/*.py` | Unit tests for validation, methods |
| `infrastructure/api/schemas/*.py` | Unit tests for DTO conversions |
| `infrastructure/database/repositories/*.py` | Integration tests for queries |
| `infrastructure/database/models/*.py` | Integration tests + migration check |
| `infrastructure/api/routes/*.py` | E2E tests for endpoints |
| `application/commands/*.py` | Unit tests for handlers |

**Check for each changed domain model:**
- Are all constructor calls updated across unit/integration/e2e tests?
- If new field added, run: `grep -r "ModelName(" --include="*.py" tests/ integration/ e2e/`

## 5. Verify test files are included

```bash
BASE=$(.cascade-notes/scripts/get_previous_branch.sh)
# Check if test files were modified alongside source files
git diff --name-only $BASE | grep -E "^(tests/|integration/|e2e/)"
```

If source files changed but no corresponding test files:
- Flag as potential missing test coverage
- List specific tests that should be added or updated

## 6. Summary Report

Provide a summary with:
- **Files changed**: List of modified files
- **Coding standard violations**: Any issues found
- **Test coverage gaps**: Missing or incomplete tests
- **Recommended actions**: Specific fixes needed before PR
