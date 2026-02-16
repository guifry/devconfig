# Chartering Fast API — Codebase Reference

## Stack

- **FastAPI 0.115** on Python 3.11
- **SQLAlchemy 2.0** (async, via asyncpg)
- **Alembic** for migrations
- **Pydantic 2.9** for domain models + validation
- **Redis** for caching
- **Poetry** for dependency management
- **Testing:** pytest 8.3, testcontainers 4.8

## Architecture

DDD / Hexagonal. Each bounded context follows:
```
context_name/
├── domain/
│   ├── models/            # Pydantic domain entities
│   └── repositories/      # Abstract repository interfaces (ABC)
├── application/
│   └── commands/          # Use case handlers
└── infrastructure/
    ├── api/               # FastAPI routes + DTOs/schemas
    ├── secondary/
    │   └── database/      # Repository implementations + SQLAlchemy {Entity}Db models
    └── cli/               # CLI commands (if any)
```

### Bounded Contexts
```
src/kpler/chartering/context/
├── cargo_list/        # Cargo orders (email, user_added, fixr)
├── tonnage_list/      # Vessel tonnage
├── fixture_list/      # Fixtures
├── user_preferences/  # User settings
└── common/            # Shared models (zones, products, org IDs)
```

### Infrastructure (shared)
```
src/kpler/infrastructure/
├── database/          # Alembic config, base models
├── cache/             # Redis
├── repositories/      # Generic repository patterns
└── api/               # Exception handlers, middleware
```

## Organisation IDs

Two types coexist:
- `MtiOrganizationId` — legacy MTI company ID (email cargo orders)
- `KplerOrganizationId` — Kpler company ID (user_added + fixr cargo orders)

**Rule:** Never expose `mti_organization_id` in API responses.

## Cargo Order Domain

### Three Sources

| Source | Domain Model | DB Table | ID Sequence | Organisation |
|--------|-------------|----------|-------------|-------------|
| `email` | `EmailCargoOrder` | `email_cargo_order` | `id SERIAL` | `mti_organization_id` |
| `user_added` | `UserAddedCargoOrder` | `user_added_cargo_orders` | `user_added_cargo_order_id_seq` | `kpler_organization_id` |
| `fixr` | `FixrCargoOrder` | `fixr_cargo_orders` | `fixr_cargo_order_id_seq` | `kpler_organization_id` |

### Base CargoOrder (shared value object)
```python
class CargoOrder(BaseModel):
    laycan: Laycan              # start, end, location (zone_id)
    quantity: CargoQuantity     # gte, lte, unit
    cargo_type: ProductId | None
    destination: CargoDestination | None
    contract_type: ContractType  # VC | TCT
    charterer: Charterer | None
```

### Source-Specific Differences

| Field | Email | User Added | Fixr |
|-------|-------|------------|------|
| Creator | Email parser (system) | `creator_id` | N/A |
| Distributor | N/A | N/A | `distributor_id` (sender) |
| Updatable | Yes (`updater_id`) | Yes (`updater_id`) | **No** (immutable) |
| Market data | Yes | Yes | Yes |
| Email metadata | `email_guid`, `sender`, `received_at` | N/A | N/A |

### CargoOrderEvent (unified view)
All three sources convert to `CargoOrderEvent` for the unified cargo list:
```python
class CargoOrderEventSource(Enum):
    EMAIL = "email"
    USER_ADDED = "user_added"
    FIXR = "fixr"

class CargoOrderEvent(BaseModel):
    cargo_order: CargoOrder
    source: CargoOrderEventSource
    creation_date: datetime
    update_metadata: UpdateMetadata | None
    market_data: CargoOrderMarketData
    email_metadata: CargoOrderEmailMetadata | None
    user_metadata: CargoOrderUserMetadata | None
    fixr_metadata: CargoOrderFixrMetadata | None
```

Factory methods: `from_email()`, `from_user_added()`, `from_fixr()`

### CargoOrdersHistory (merged timeline)
Merges all sources chronologically:
```python
CargoOrdersHistory.from_user_email_and_fixr_cargo_orders(
    user_orders, email_orders, fixr_orders
)
```
Backward-compatible factory: `from_user_and_email_cargo_orders()` delegates with empty fixr list.

## Cargo Order Retrieval

### Flow
```
POST /api/v1/chartering/cargo-orders (with filters)
  → RetrieveCargoOrdersHandler
    → check source_filter:
       null    → fetch all three sources
       "email" → fetch email only
       "user_added" → fetch user only
       "fixr"  → fetch fixr only
    → merge into CargoOrdersHistory (chronological sort)
    → convert to CargoOrderEventResponse[]
```

### Filter System
Each repository implements the same filter interface. 12 filter types:

| Filter | Description | Fixr special case |
|--------|-------------|-------------------|
| laycan_date_range | Laycan start/end overlap | Normal |
| origin_zones | Zone ancestor hierarchy | Normal |
| destination_zones | Zone ancestor hierarchy | Normal |
| cargo_types | Product ancestor hierarchy | Normal |
| quantity_range | Min/max overlap logic | Normal |
| contract_types | VC/TCT | Normal |
| player | Player ID IN | Normal |
| commercial_status | Status IN | Normal |
| tce/rate/lumpsum | Range filters | Normal |
| received_at | Creation date range | Maps to `created_at` |
| edited_at | Update date range | **Returns empty** (fixr immutable) |

Hierarchical filters (zones, products) use SQLAlchemy joins with `ZoneDb.ancestors` / `ProductDb.sorted_ancestors` arrays.

## Database Schema — Fixr Cargo Orders

```sql
Table: fixr_cargo_orders
Sequence: fixr_cargo_order_id_seq

id                          INTEGER PRIMARY KEY (from sequence)
kpler_organization_id       VARCHAR NOT NULL
distributor_id              VARCHAR NOT NULL
distributor_organization_id VARCHAR NULL
created_at                  TIMESTAMP

-- Cargo fields (same as user_added)
laycan_start            DATE
laycan_end              DATE
laycan_zone_id          INTEGER
destination_zone_id     INTEGER
destination_timestamp   TIMESTAMP
quantity_gte            DECIMAL
quantity_lte            DECIMAL
quantity_unit           VARCHAR
cargo_type              INTEGER
contract_type           VARCHAR
player_id               INTEGER
player_name             VARCHAR
comment                 TEXT

-- Market data
commercial_status       VARCHAR
tce                     DECIMAL
rate                    DECIMAL
lumpsum                 DECIMAL

-- Vessel (matched)
vessel_id               INTEGER
vessel_imo              VARCHAR
vessel_name             VARCHAR

Permissions: SELECT, INSERT, UPDATE, DELETE for chartering_fast_api
```

**Key difference from user_added:** `distributor_id`/`distributor_organization_id` instead of `creator_id`/`updater_id`. No update fields (immutable).

## API Endpoints — Cargo Orders

| Method | Path | Description |
|--------|------|-------------|
| POST | `/cargo-orders` | Search/filter all sources (with source_filter) |
| POST | `/fixr-cargo-orders` | Create fixr cargo order |
| POST | `/user-added-cargo-orders` | Create user-added order |
| GET | `/user-added-cargo-orders/{id}` | Get single user order |
| GET | `/email-cargo-orders/{id}` | Get single email order |
| PUT | `/user-added-cargo-orders/{id}` | Update user order |
| PUT | `/email-cargo-orders/{id}` | Update email order |
| DELETE | `/user-added-cargo-orders/{id}` | Delete user order |
| DELETE | `/email-cargo-orders/{id}` | Delete email order |

### Create Fixr Cargo Order
```
POST /api/v1/chartering/fixr-cargo-orders
Body: CargoOrderCreateQuery (same as user-added)
Auth: Bearer token → distributor_id from user.id, kpler_organization_id from JWT
Response: FixrCargoOrderDto { id, cargo_order, market_data, distributor_metadata, creation_metadata }
```

### Response DTOs
```python
class FixrDistributorMetadataDto(BaseModel):
    distributor_id: str
    distributor_organization_id: str | None

class FixrCreationMetadataDto(BaseModel):
    created_at: datetime
```

## Naming Conventions

| Concern | Convention | Example |
|---------|-----------|---------|
| Domain model | PascalCase | `FixrCargoOrder` |
| DB model | `{Entity}Db` | `FixrCargoOrderDb` |
| Repository interface | `{Entity}Repository` (ABC) | `FixrCargoOrdersRepository` |
| Repository impl | `{Entity}RepositoryDb` | `FixrCargoOrdersRepositoryDb` |
| Command | `Add{Entity}Command` | `AddFixrCargoOrderCommand` |
| Handler | `Add{Entity}Handler` | `AddFixrCargoOrderHandler` |
| DTO/Schema | `{Entity}Dto` / `{Entity}Response` | `FixrCargoOrderDto` |
| Migration | Alembic auto-generated name | `6765dfd7c463_add_fixr_cargo_order_table` |

## Key Files — Cargo Orders

### Fixr source
| Concern | Path |
|---------|------|
| Domain model | `context/cargo_list/domain/models/cargo_order/fixr_cargo_order.py` |
| Repository interface | `context/cargo_list/domain/repositories/fixr_cargo_orders_repository.py` |
| Repository impl | `context/cargo_list/infrastructure/secondary/database/fixr_cargo_orders_repository_db.py` |
| DB model | `context/cargo_list/infrastructure/secondary/database/schemas/fixr_cargo_order_db.py` |
| Migration | `infrastructure/database/alembic/versions/6765dfd7c463_add_fixr_cargo_order_table.py` |
| Command | `context/cargo_list/application/commands/cargo_orders/add_fixr_cargo_order.py` |
| API route | `context/cargo_list/infrastructure/api/cargo_orders.py` |
| DTO | `context/cargo_list/infrastructure/api/schemas/cargo_order_schema.py` |

### Shared
| Concern | Path |
|---------|------|
| Base CargoOrder | `context/cargo_list/domain/models/cargo_order/cargo_order.py` |
| CargoOrderEvent | `context/cargo_list/domain/models/cargo_order/cargo_order_event.py` |
| CargoOrdersHistory | `context/cargo_list/domain/models/cargo_order/cargo_orders_history.py` |
| Filters | `context/cargo_list/domain/models/cargo_list/cargo_list_filters.py` |
| Retrieve command | `context/cargo_list/application/commands/cargo_orders/retrieve_cargo_orders.py` |
| Organisation IDs | `context/common/domain/models/organization_id.py` |

All paths relative to `src/kpler/chartering/`.

## Testing Patterns

| Type | Location | Data pattern |
|------|----------|-------------|
| Unit (`tests/`) | Inline or local fixtures | Instantiate objects directly |
| Integration (`integration/`) | `@pytest_asyncio.fixture(scope="function")` | Never create DB entities inside test functions |
| E2E (`e2e/`) | `entities_generation.py` for DB seed | Use `entities_generation` module |

### Company Isolation (mandatory in E2E)
```python
# Company A creates → Company B must get 404
create_response = api_server.post(endpoint, json=body, headers=headers_company_a)
get_response = api_server.get(f"{endpoint}/{id}", headers=headers_company_b)
assert get_response.status_code == 404
```

## Session Management

Sessions managed by middleware. **Never** `flush()` or `commit()` in repository code.
