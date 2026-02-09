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

### 4. Verify All New Code Is Used

For every new public function, method, or class added in the diff:
1. Search the entire codebase (`src/`, `e2e/`, `integration/`, `tests/`) for usages beyond the definition itself
2. Flag any symbol that is defined but never called/referenced anywhere
3. Pay special attention to:
   - Domain model methods — are they called by a handler, service, or test?
   - Repository methods — are they called by a handler or integration test?
   - DTO/schema classes — are they referenced in a route or response?
   - Helper/utility functions — is there at least one caller?

**Only flag code added in this branch's diff. Do not touch pre-existing code. Remove dead code added by this branch. If a method exists only to "be available later", it should not be in the PR.**

### 5. Check ORM ↔ Domain Type Consistency

For every new or modified DB schema (`{Entity}Db` class) in the diff:
1. Read the corresponding domain model (Pydantic class) that the schema maps to/from
2. For each `mapped_column`, verify the `Mapped[X]` type matches the domain field type:
   - Domain `int` → `Mapped[int]`, not `Mapped[float]`
   - Domain `float` → `Mapped[float]`, not `Mapped[int]`
   - Domain `str` → `Mapped[str]`
   - Domain `X | None` → `Mapped[X | None]` with `nullable=True`
3. Also check `from_domain()` and `to_domain()` for silent type coercions (e.g. `int` field stored as `float`)

**Auto-fix type mismatches.**

### 6. Check Timestamp Creation Layer

`utc_now_tz_unaware()` must only be called in the application layer (`application/commands/` handlers). The pattern is:
```python
# In handler __init__:
self.now = utc_now_tz_unaware()
# Then pass self.now as parameter to domain methods and repositories
```

Flag any `utc_now_tz_unaware()` call in:
- `domain/` — never. Timestamps are passed in as arguments.
- `infrastructure/secondary/database/` (repositories) — never for business timestamps. The only exception is internal caching logic (e.g. `cache.last_time_updated`).
- `infrastructure/api/` (routes) — never. Delegate to handler.

Also flag `datetime.now()`, `datetime.utcnow()`, or `date.today()` anywhere — always use `utc_now_tz_unaware()` from `kpler.infrastructure.date`.

**Auto-fix by moving timestamp creation to the handler and passing it as a parameter.**

### 7. Check Test Placement

Tests MUST be in the correct directory based on what they test. Verify placement for every test file in the diff:

| What the test exercises | Correct directory | Wrong directory |
|------------------------|-------------------|-----------------|
| Domain model (Pydantic validation, methods, factories) | `tests/` | `integration/`, `e2e/` |
| DTO/Schema conversion (`from_domain`, `to_domain`) | `tests/` | `integration/`, `e2e/` |
| Pure functions, transformations, calculations | `tests/` | `integration/`, `e2e/` |
| Repository CRUD, SQL filters (needs real DB) | `integration/` | `tests/`, `e2e/` |
| API endpoint behaviour, auth, HTTP status codes | `e2e/` | `tests/`, `integration/` |

Red flags to check:
- Test in `integration/` that doesn't use a DB session or fixture → should be a unit test in `tests/`
- Test in `tests/` that requires database setup → should be in `integration/`
- `from_domain()`/`to_domain()` roundtrip test in `integration/` → move to `tests/`

**Move misplaced tests to the correct directory.**

### 8. Check Test Coverage Requirements

Analyse the diff to determine required tests:

| Change Type | Required Test |
|------------|---------------|
| New API route (`infrastructure/api/`) | E2E test |
| New repo method (`infrastructure/secondary/database/`) | Integration test |
| Domain model change (`domain/models/`) | Unit test |
| New DB schema (`infrastructure/secondary/database/schemas/`) | Unit test for `from_domain`/`to_domain` roundtrip |
| New DTO/response schema (`infrastructure/api/schemas/`) | Unit test for `from_domain` |
| 404/error edge cases | E2E test |
| Company-scoped endpoints | E2E company isolation test |

**Company isolation tests must include all three steps:**
1. Write/create as company A
2. Read-back as company B
3. Assert company B cannot see company A's data (404 or empty result)

Two writes from different companies alone is NOT a valid isolation test — there must be a cross-company read attempt.

**Write missing tests following patterns in existing test files.**

### 9. Run Test Suites (Fix Until Pass)

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

### 10. Run Pre-commit (Fix Until Pass)

```bash
pre-commit run --all-files
```

Fix any failures and re-run until all checks pass.

### 11. Index Review (Report Only)

**Only run this step if the diff includes Alembic migrations or changes to `{Entity}Db` schemas.**

For each new or modified table/column:
1. Check which columns have `index=True`
2. Flag columns that are indexed but unlikely to be filtered or sorted on (e.g. free-text fields, vessel names, comments)
3. Flag columns that are NOT indexed but likely will be filtered on (e.g. foreign keys, status fields, date fields used in range queries)
4. Check consistency with similar tables — if `user_added_cargo_orders` indexes a column, the equivalent column in `fixr_cargo_orders` probably should too

**This step is report-only — unlike all other steps which auto-fix issues, index review findings are ONLY reported in the final summary for manual review. This exception applies exclusively to this step (step 11). All other steps must continue to auto-fix as instructed.**

### 12. Report Status

Summarise:
- Convention violations found and fixed
- Dead code found and removed
- Type mismatches found and fixed
- Timestamp layer violations found and fixed
- Misplaced tests found and moved
- Tests added
- Test results (all passing / failures remaining)
- Pre-commit status
- Index review findings (if applicable)
- Ready to push: Yes/No
- Any unfixable issues requiring manual intervention
