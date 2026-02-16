---
description: Backend-specific context and patterns
paths:
  - chartering-fast-api/**
---

# Chartering Fast API Rules

## Stack
FastAPI 0.115, Python 3.11, SQLAlchemy 2.0 (async), Alembic, Pydantic 2.9, PostgreSQL.

## Architecture
DDD / Hexagonal with bounded contexts:
```
context/{name}/domain/models/     → Pydantic entities
context/{name}/domain/repositories/ → ABC interfaces
context/{name}/application/commands/ → Use case handlers
context/{name}/infrastructure/api/  → Routes + DTOs
context/{name}/infrastructure/secondary/database/ → {Entity}Db + RepositoryDb
```

## Cargo Order Sources
Three source types: `email`, `user_added`, `fixr`.
Each has own table with independent integer sequences.
Unified via `CargoOrderEvent` with source-specific metadata.
Retrieval merges all three chronologically in `CargoOrdersHistory`.

## Key Conventions
- `{Entity}Db` naming for SQLAlchemy models
- `@property` for boolean checks
- Composition over inheritance (factory functions)
- Module-level logger
- `utc_now_tz_unaware()` for timestamps
- Never `flush()`/`commit()` in repository code (middleware manages sessions)
- Never expose `mti_organization_id` in API responses
- Two org types: `MtiOrganizationId` (email), `KplerOrganizationId` (user_added + fixr)

## Full reference
- Codebase: `docs/codebase/chartering-fast-api/CHARTERING_FAST_API.md`
- Feature: `docs/features/fixr/` (distribution flow, architecture, PRs)
