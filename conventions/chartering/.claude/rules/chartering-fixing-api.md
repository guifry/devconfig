---
description: Fixing API context and patterns
paths:
  - chartering-fixing-api/**
---

# Chartering Fixing API Rules

## Stack
NestJS v11 on Fastify, TypeScript, Knex query builder (no ORM), PostgreSQL.
Schema: `fixr`. DB user: `fixing_api`.

## Architecture
Hexagonal: `application/` (controllers, DTOs, guards) → `domain/` (services, types) → `infrastructure/` (database, config).
Six domain modules: cargo-order, distribution, offer, contact, activity, share-token.

## Key Patterns
- **Direct SQL via Knex** — no ORM. Query builder in services, raw SQL in status query builder.
- **PG LISTEN/NOTIFY for SSE** — trigger on `offer` table → `pg_notify('offer_changes')` → PgNotifyService → RxJS Subject → SSE endpoints.
- **Cargo snapshot on distribution** — distribution table stores immutable copy of cargo fields at send time.
- **Self-referencing offers** — `in_reply_to_id` for negotiation chains, grouped by contact+vessel.
- **Cryptographic share tokens** — 48-byte random base64url, 7-day default expiry.
- **Auto-create contacts from email** — domain extraction for company_name when email not found.

## Auth
JWT decoded from `x-access-token` header. Permissions are zlib-compressed in JWT payload.
Guards: DecodeUserPayload → CheckPermissions → CheckScopes (global, ordered).
Decorators: `@NoAuth()`, `@RequirePermissions()`, `@RequireScopes()`, `@User()`.

## Status Logic
`fixed` > `on_subs` > `update` (pending offers) > `distributed` (sent distributions) > `draft`

## Full reference
- Codebase: `docs/codebase/chartering-fixing-api/FIXING_API.md`
- Feature: `docs/features/fixr/` (distribution flow, architecture, PRs)
