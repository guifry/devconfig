---
name: review-chartering-api
description: Review all changes on current branch against coding standards and test coverage
allowed-tools: Bash, Read, Grep, Glob, Edit, Write
---

# Chartering API PR Review

Review all changes on current branch against CLAUDE.md conventions and test coverage requirements.

## Execution Steps

### 1. Identify Changes

```bash
BASE=$(git merge-base HEAD main 2>/dev/null || git merge-base HEAD develop 2>/dev/null || git merge-base HEAD master)
git diff $BASE --name-only
git diff $BASE
```

### 2. Read Conventions

Read `../CLAUDE.md` (parent of chartering-fast-api) to understand all coding standards.

### 3. Analyse & Fix Convention Violations

For each changed Python file, check:
- No `mti_organization_id` exposed in API responses
- Composition over inheritance (factory functions, not subclasses)
- `@property` for boolean checks
- Logger at module level, not class field
- All imports at file top (no inline imports)
- `{Entity}Db` naming pattern
- `utc_now_tz_unaware()` instead of `datetime.now()`
- No docstrings for classes/functions/modules
- No unnecessary comments

**Auto-fix all violations found.**

### 4. Check Test Coverage Requirements

Analyse the diff to determine required tests:

| Change Type | Required Test |
|------------|---------------|
| New API route (`interface/routers/`) | E2E test |
| New repo method (`infrastructure/repositories/`) | Integration test |
| Domain model change (`domain/models/`) | Unit test |
| 404/error edge cases | E2E test |

**Write missing tests following patterns in existing test files.**

### 5. Run Test Suites (Fix Until Pass)

Run each suite, fix failures, repeat until all pass:

```bash
cd chartering-fast-api

# Unit tests
pytest tests/ -v --tb=short

# Integration tests
pytest integration/ -v --tb=short

# E2E tests
pytest e2e/ -v --tb=short
```

### 6. Run Pre-commit (Fix Until Pass)

```bash
pre-commit run --all-files
```

Fix any failures and re-run until all checks pass.

### 7. Report Status

Summarise:
- Convention violations found and fixed
- Tests added
- Test results (all passing / failures remaining)
- Pre-commit status
- Ready to push: Yes/No
- Any unfixable issues requiring manual intervention
