# Chartering Fixing API — Codebase Reference

## Stack

- **NestJS v11** on Fastify (not Express)
- **TypeScript 5.9**, **Knex** query builder (no ORM), **PostgreSQL**
- **Real-time**: PostgreSQL LISTEN/NOTIFY + SSE via RxJS
- **Auth**: JWT from `x-access-token` header, zlib-compressed permissions
- **Share app**: Embedded Vue 3 SPA (`share-offer-app/`) served via ServeStatic at `/share`

## Architecture

```
src/
├── application/          # HTTP layer
│   ├── controllers/
│   │   ├── fixr/        # Main API (cargo, distribution, offer, contact, activity, SSE)
│   │   ├── share/       # Public share endpoints (no auth)
│   │   └── health/
│   ├── decorators/      # @NoAuth, @RequirePermissions, @RequireScopes, @User
│   └── types/
├── domain/              # Business logic
│   ├── cargo-order/     # Cargo CRUD + status transitions
│   ├── distribution/    # Distribution CRUD + cargo snapshots
│   ├── offer/           # Offer CRUD + negotiations + accept/reject
│   ├── contact/         # Contact CRUD
│   ├── activity/        # Activity logging
│   ├── share-token/     # Token generation + validation
│   └── model/           # User/license models
└── infrastructure/
    ├── configuration/   # Env vars
    └── database/        # Knex connection, migrations, PgNotify service
```

## Domain Ports (Hexagonal)

### UserRegistryPort
Resolves email → `{ user_id, kpler_org_id, name }`. Used during distribution to identify recipients.
- `InMemoryUserRegistryAdapter` — 5 hardcoded mock users (current)
- Real adapter needed (not yet implemented)

### CharteringApiPort
Creates fixr cargo orders in Chartering Fast API. Returns the new cargo order ID.
- `HttpCharteringApiAdapter` — POST to Chartering Fast API with forged JWT containing recipient's `kpler_org_id`
- Config: `CHARTERING_API_BASE_URL`

## Database

**Schema:** `fixr` (PostgreSQL)
**Query builder:** Knex (not an ORM — raw SQL via builder)
**Migration tracking:** `fixr.fixing_migrations` table
**DB user:** `fixing_api`

### Tables

#### contact
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | gen_random_uuid() |
| kpler_org_id | UUID NOT NULL | Indexed |
| company_name | VARCHAR NOT NULL | |
| type | ENUM('owner','broker','charterer') | Nullable |
| address, country, contact_name, title, email, phone, whatsapp | Various | All nullable |
| created_at, updated_at | TIMESTAMP | Defaults now() |

Indexes: `(kpler_org_id, company_name)`, `(kpler_org_id, email)`

#### cargo_order
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | gen_random_uuid() |
| kpler_org_id | UUID NOT NULL | |
| external_cargo_id | VARCHAR NOT NULL | Reference to Chartering Fast API cargo |
| cargo_type, vessel_type, charterer | VARCHAR | Nullable |
| quantity_min, quantity_max | DECIMAL(15,3) | Nullable |
| quantity_unit | VARCHAR | Default 'MT' |
| laycan_start, laycan_end | DATE | Nullable |
| load_area, load_port, discharge_area, discharge_port | VARCHAR | Nullable |
| is_distributed, is_on_subs, is_fixed, is_archived | BOOLEAN | Default false |
| created_by | UUID | Nullable |

Unique: `(kpler_org_id, external_cargo_id)` — INSERT returns 409 Conflict on duplicate.

**Columns added in PRs #19–#23:**
| Column | Type | Notes |
|--------|------|-------|
| source | VARCHAR NOT NULL | `'email'`, `'user'`, `'fixer'` |
| source_cargo_id | VARCHAR NOT NULL | Raw ID from the source system (no prefix) |
| parent_cargo_order_id | VARCHAR NULL | References another row's `external_cargo_id` |

- `external_cargo_id` is now built by `buildExternalCargoId(source, id)` → `e123`/`u456`/`f789`
- Index on `(kpler_org_id, parent_cargo_order_id)` for distribution tree lookups

#### distribution
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| kpler_org_id | UUID NOT NULL | |
| cargo_order_id | VARCHAR NOT NULL | External cargo ref (not FK) |
| contact_id | UUID FK → contact | CASCADE |
| sent_at, sent_by | TIMESTAMP/UUID | Nullable |
| read_at | TIMESTAMP | Nullable |
| is_ai_suggested | BOOLEAN | Default false |
| ai_ranking | ENUM('ideal','viable') | Nullable |
| ai_reasoning | TEXT | Nullable |
| ai_suitable_tonnage | INT | Nullable |
| **cargo snapshot fields** | Various | Copied at distribution time |

Unique: `(kpler_org_id, cargo_order_id, contact_id)` — one distribution per contact per cargo

**Snapshot pattern:** Distribution stores cargo details at distribution time. Immutable record even if cargo changes later.

#### offer
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| kpler_org_id | UUID NOT NULL | |
| cargo_order_id | VARCHAR NOT NULL | External cargo ref |
| contact_id | UUID FK → contact | **Nullable** (migration 012) |
| vessel_id, vessel_imo, vessel_name, vessel_dwt, vessel_flag | Various | Nullable |
| nominating_as | VARCHAR | Nullable |
| is_firm, is_indicative, is_counter_offer | BOOLEAN | Defaults false |
| in_reply_to_id | UUID FK → offer(id) | Self-referencing, SET NULL |
| freight_rate | DECIMAL(15,4) | Nullable |
| demurrage_rate | DECIMAL(15,4) | Nullable |
| laycan | DATE | Nullable |
| operational_subs, commercial_subs, misc_subs | TEXT | Nullable |
| is_accepted, is_rejected | BOOLEAN | Defaults false |
| accepted_at, rejected_at, rejection_reason | Various | |
| ai_risk_level | ENUM('best_offer','viable','high_risk') | Nullable |
| ai_risk_reasoning, ai_price_comparison, ai_evaluated_at | Various | |
| expires_at | TIMESTAMP | Nullable |

**Trigger:** `offer_change_trigger` → `notify_offer_change()` → `pg_notify('offer_changes', {operation, cargo_order_id, kpler_org_id})`

#### cargo_order_activity
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| cargo_order_id | VARCHAR NOT NULL | |
| actor_type | ENUM('user','counterparty','system','ai_agent') | |
| action_type | ENUM('order_created','distributed','offer_received','counter_offer_sent','offer_accepted','offer_rejected','moved_to_subs','fixed','archived') | |
| related_offer_id | UUID FK → offer | SET NULL |
| related_contact_id | UUID FK → contact | SET NULL |

#### share_token
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| organization_id | UUID NOT NULL | |
| distribution_id | UUID FK → distribution | Nullable, CASCADE |
| offer_id | UUID FK → offer | Nullable, CASCADE |
| token | VARCHAR(128) UNIQUE | crypto.randomBytes(48).toString('base64url') |
| expires_at | TIMESTAMP NOT NULL | Default 168h (7 days) |
| is_revoked | BOOLEAN | Default false |
| access_count | INT | Default 0 |

Token links to EITHER a distribution OR an offer, not both.

## Domain Services

### CargoOrderService
- `findAll(orgId, filters?)` — list with optional boolean filters
- `findById/findByExternalId` — lookup
- `findActionRequired(orgId)` — cargos with pending offers (not accepted/rejected/expired)
- `findOnSubs(orgId)` — is_on_subs=true, not fixed/archived
- `create/update/delete` — CRUD
- `markDistributed/markOnSubs/markFixed/archive` — status transitions
- `getStatusesByExternalIds(orgId, ids[])` — batch status query

### Status Logic (`cargo-order-status.query-builder.ts`)
```
fixed      if is_fixed = true
on_subs    if is_on_subs = true
update     if has pending offers (not accepted/rejected)
distributed if has sent distributions (sent_at NOT NULL)
draft      otherwise
```

**Planned rename:** `update` → `negotiating` (planned for demo — may or may not be merged).

### DistributionService
- `findByCargoOrder/findById/findByIdWithContact` — queries
- `create/createMany` — single or bulk
- `markSent(orgId, id, sentBy)` — set sent_at
- `markRead(orgId, id)` — set read_at (only if null)
- `delete/deleteByCargoOrder`

**`bulk-email` flow (PRs #19–#23):** Resolves each recipient email via `UserRegistryPort` (422 if unknown user). Creates a fixr cargo order per recipient via `CharteringApiPort`. Stores child orders with `f` prefix and `parent_cargo_order_id` pointing to the source cargo. Creates contacts for each recipient. Marks parent cargo as distributed.

### OfferService
- `findByCargoOrder/findById/findByCargoOrderAndContact` — queries
- `findPendingOffers(orgId)` — not accepted/rejected, not expired
- `create/update/delete`
- `accept(orgId, id)` — sets is_accepted + accepted_at
- `reject(orgId, id, reason?)` — sets is_rejected + rejected_at + reason
- `getNegotiationsForCargo(orgId, cargoOrderId)` — groups offers by contact+vessel, returns NegotiationDto[]

### ContactService
- `findAll/findById/findByEmail/findByCompanyName(ILIKE)` — queries
- `create/update/delete`

### ActivityService
- `findByCargoOrder/findRecent(limit=50)` — queries with JOINs
- Helper loggers: `logOrderCreated`, `logDistributed`, `logOfferReceived`, `logOfferAccepted`, `logOfferRejected`

### ShareTokenService
- `create(orgId, {distribution_id|offer_id, expires_in_hours})` — generates 48-byte random token
- `validateToken(token)` — checks revoked/expired, increments access_count
- `findByDistributionId/findByOfferId` — active tokens lookup
- `revoke/revokeAllForDistribution/revokeAllForOffer`
- `buildShareUrl(baseUrl, token)` — constructs share URL

## SSE (Real-time)

### Architecture
PostgreSQL LISTEN/NOTIFY → PgNotifyService (dedicated connection, EventEmitter) → RxJS Subject → SSE endpoints

### Endpoints
| Path | Behaviour |
|------|-----------|
| `GET /fixr/offers/stream` (SSE) | All offer changes: `{type, cargo_order_id, operation}` |
| `GET /fixr/offers/cargo-orders/:id/stream` (SSE) | Single cargo: initial count + updates `{cargo_order_id, count, unique_contacts}` |
| `GET /fixr/offers/cargo-orders/batch/stream` (SSE) | Batched every 2s: `{type, updates: [{cargo_order_id, count, unique_contacts}]}` |

PgNotifyService auto-reconnects on error (5s delay), uses separate PG client outside Knex pool.

## Auth System

### JWT Decoding
- Header: `x-access-token` (not `Authorization`)
- Decode: split `.`, base64-decode payload part
- Permissions: base64 → zlib inflate → JSON array
- Claims: `email`, `sub`, `https://kpler.com/user_id`, `scope`, compressed permissions

### Guards (global, ordered)
1. `DecodeUserPayloadGuard` — always runs, builds AuthenticatedUser/Machine/Unauthenticated
2. `CheckPermissionsGuard` — checks `@RequirePermissions([])`
3. `CheckScopesGuard` — checks `@RequireScopes([])`

### Decorators
- `@NoAuth()` — skip auth entirely
- `@RequirePermissions(['perm1', 'perm2'])` — AND logic
- `@RequireScopes(['scope1'])` — AND logic
- `@User()` — extract authenticated user from request

## Configuration

```bash
SERVER_HOST=localhost
SERVER_PORT=3001
POSTGRES_HOST=localhost
POSTGRES_PORT=5435
POSTGRES_USER=kpler
POSTGRES_PASSWORD=kpler-fixr
POSTGRES_DATABASE=fixr
SHARE_APP_BASE_URL=http://localhost:3002  # Share URL construction
CHARTERING_API_BASE_URL=...               # For HttpCharteringApiAdapter
```

CORS: `dev.kpler.com:8080`, `localhost:8080`

## Patterns

- **Snapshot at distribution time** — distribution stores cargo details immutably
- **Direct SQL via Knex** — no ORM, explicit queries
- **PG LISTEN/NOTIFY for SSE** — no Redis/WebSocket needed
- **Cryptographic share tokens** — 48-byte random, base64url encoded
- **Auto-create contacts from email** — domain extraction for company_name
- **Self-referencing offers** — `in_reply_to_id` for negotiation chains
- **Activity logging** — audit trail for all cargo lifecycle events
