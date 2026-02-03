# Claude Code Guidelines for Chartering

Guidelines for working in this workspace containing:
- **chartering-fast-api/** - Python backend (FastAPI)
- **web-app/** - Frontend

---

# Backend (chartering-fast-api)

## Security

**Never leak `mti_organization_id` in API responses:**
```python
# ❌ BAD
class FixtureEmailMetadataResponse(BaseModel):
    mti_organization_id: str  # Exposes internal ID!

# ✅ GOOD - Omit internal IDs from responses
```

**Always test company isolation** - add tests ensuring users can't access other companies' data.

---

## Python Code Style

- Use type hints consistently
- Optimise for readability over premature optimisation
- **NEVER add module-level docstrings**
- **NEVER add docstrings for classes and functions/methods**
- Write as few comments as possible - only for intricate logical statements
- **Remove AI prompts from code comments** - never leave TODO/FIXME referencing AI assistance
- **NEVER use `__init__.py` for import/export** - leave them empty
- **All imports at file top** - never inside functions. Only exception: circular imports with documenting comment

**Logger at module level:**
```python
# ❌ BAD - Logger as class field
class Handler:
    def __init__(self): self._logger = logging.getLogger(__name__)

# ✅ GOOD - Module level
logger = logging.getLogger(__name__)
class Handler: ...
```

**Consistent naming:** `{Entity}Db` pattern (e.g., `KplerFixtureDb` not `DbKplerFixture`).

**File names match class names** - `update_metadata.py` for `UpdateMetadata`.

---

## Architecture

**Composition over inheritance:**
```python
# ❌ BAD - Inheritance for factory behaviour
class SystemDefaultPrefs(ColumnPreferences):
    def __init__(self): super().__init__(...)

# ✅ GOOD - Factory function
def system_default_prefs() -> ColumnPreferences:
    return ColumnPreferences(...)
```

**Use `@property` for boolean checks:**
```python
# ❌ BAD
def is_user_added(self) -> bool: return self.source == FixturesSource.USER_ADDED

# ✅ GOOD
@property
def is_user_added(self) -> bool: return self.source == FixturesSource.USER_ADDED
```

**Reuse existing constants** - e.g., `MANDATORY_CUSTOM_PARENT_OWNERS_FILTERS` instead of manual joins.

**Extract repeated patterns** into helpers (e.g., `convert_vessel_type()`).

---

## Domain Design

**Explicit nullability - no defaults in domain:**
```python
# ❌ BAD
class Location(BaseModel):
    name: str | None = None  # Hidden default

# ✅ GOOD
class Location(BaseModel):
    name: str | None  # Must be explicit
```

**Optional at single level** - avoid `product: Product | None` where `Product` also has `id: int | None`.

**Match DTO types to behaviour** - if code handles `None`, type should include `| None`.

---

## Database & Migrations

**Grant proper permissions in migrations:**
```python
# For immutable email data
op.execute("GRANT SELECT ON TABLE public.email_fixtures TO chartering_fast_api;")
# For AIS sink
op.execute("GRANT SELECT, INSERT, UPDATE ON TABLE public.email_fixtures TO ais_user;")
```

**Always check for missing migrations** when adding ORM columns.

**NEVER use `flush()` or `commit()` in repository code:**
Sessions are managed at endpoint level via middleware context manager. Commit happens automatically at end of request.
```python
# ❌ BAD - manual flush/commit in repository
await self.session.merge(entity)
await self.session.flush()

# ✅ GOOD - let middleware handle commit
await self.session.merge(entity)
```
If tests fail due to session timing, fix test infrastructure, not repository code.

---

## Date/Time

```python
# ❌ BAD
self.today = datetime.now()

# ✅ GOOD
from kpler.infrastructure.date import utc_now_tz_unaware
self.now = utc_now_tz_unaware()
self.today_date = self.now.date()
```

---

## Performance & DevOps

- **5s timeout** for user-facing operations (not 30s)
- **ID-based filtering** over string filtering for indexing
- **Consistent types** - use `str` for org IDs everywhere

---

## Testing

### Test Data Location

| Test Type | Data Location | Pattern |
|-----------|---------------|---------|
| Unit (`tests/`) | Inline or local `fixtures.py` | Instantiate objects directly |
| Integration (`integration/`) | Top of file with `@pytest_asyncio.fixture(scope="function")` | Never create DB entities inside test functions |
| E2E (`e2e/`) | `entities_generation.py` for DB seed, `fixtures.py` for DTOs | Use `entities_generation` module |

### Unit Tests (`tests/`)

**What to test:**
- Domain model validation (Pydantic constraints, custom validators)
- Domain model methods (`create()`, `update()`, factory methods)
- DTO/Schema conversions (`to_domain()`, `from_domain()`)
- Business logic validation (range checks, date ordering)
- Pure functions (transformations, calculations)

### Integration Tests (`integration/`)

**What to test:**
- Repository CRUD operations
- SQL filter logic with real database
- Hierarchical data relationships (zones with ancestors, products with descendants)
- Database roundtrip (domain → DB → domain)
- Transaction behaviour

### E2E Tests (`e2e/`)

**What to test:**
- API endpoint behaviour (HTTP status codes, response structure)
- Authentication and authorisation
- Company isolation (company A cannot access company B's resources)
- Full CRUD cycles
- Validation error responses (422 for invalid input)

### Anti-Patterns

```python
# ❌ NEVER in integration/e2e - data inside test function
async def test_filter(session_scoped_db):
    order = EmailCargoOrderDb(id=1, ...)
    session_scoped_db.add(order)

# ❌ NEVER duplicate fixture data - extend existing fixtures instead

# ✅ GOOD - use fixture references
from e2e.domain_entities_generation.entities_generation import VESSEL_IMO_1
assert response["imo"] == str(VESSEL_IMO_1)
```

### Company Isolation Pattern

Always test cross-company access in E2E tests:
```python
def test_company_isolation(api_server):
    company_a = "company_a_org_id"
    company_b = "company_b_org_id"

    # Create resource as company A
    create_response = api_server.post(ENDPOINT, json=body, headers=headers_company_a)
    resource_id = create_response.json()["id"]

    # Company B should NOT see it → 404
    get_response = api_server.get(f"{ENDPOINT}/{resource_id}", headers=headers_company_b)
    assert get_response.status_code == 404
```

### Key Test Files

| Purpose | Location |
|---------|----------|
| Integration DB setup | `integration/conftest.py` |
| E2E full setup | `e2e/conftest.py` |
| E2E DB seed data | `e2e/domain_entities_generation/entities_generation.py` |
| E2E auth helpers | `e2e/common/auth_fixtures.py` |

---

## Pre-commit Workflow

Before committing, run until all checks pass:
```bash
pre-commit run --all-files
```

---

## Branch Review Checklist

When reviewing changes on a branch:

1. **Only review/fix code changed in this branch** - do NOT refactor pre-existing code
2. Check against coding standards above
3. Verify test coverage:
   - `domain/models/*.py` → Unit tests
   - `infrastructure/database/repositories/*.py` → Integration tests
   - `infrastructure/api/routes/*.py` → E2E tests
4. Ensure all constructor calls updated when adding new fields

**Key checks:**
- No `mti_organization_id` exposed in API responses
- Composition over inheritance (factory functions, not subclasses)
- `@property` for boolean checks
- Logger at module level, not class field
- All imports at file top
- `{Entity}Db` naming pattern
- `utc_now_tz_unaware()` instead of `datetime.now()`

**Find inline imports in changed files:**
```bash
BASE=$(git merge-base HEAD main)
git diff $BASE --name-only -- "*.py" | xargs -I {} grep -n "^    from \|^        from " {} 2>/dev/null
```

---

## Workflow: Study-Plan-Implement

For complex features:

1. **Study**: Search codebase to understand context, identify all relevant files, patterns and dependencies. Note ambiguities.
2. **Plan**: Create implementation plan with:
   - TL;DR: 1-line understanding + bullet list of steps (max 5-7)
   - Detailed requirements and acceptance criteria
   - Technical implementation with file paths
   - Open questions to confirm with user
3. **Implement**: On user confirmation, execute step by step. **Pause and ask if new questions arise.**
4. **Validate**: Verify all acceptance criteria satisfied. Summarise what was done and any deviations.

---

# Frontend (web-app)

## Commit Message Convention

Use conventional commits with domain scope:
```
type(domain): description
```

**Examples:**
- `feat(chartering): add rate filter for fixtures`
- `fix(chartering): handle null rate in column formatter`
- `chore(chartering): sync openapi.json and regenerate types`
- `refactor(compliance): update widget layout`

**Types:** `feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `perf`

**Domain** is the workspace/feature area (e.g., `chartering`, `compliance`, `natgas`, `power`).

---

*More guidelines to be added*
