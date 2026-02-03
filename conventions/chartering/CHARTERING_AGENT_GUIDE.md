# Chartering Full-Stack Agent Guide

Reference documentation for AI agents working on the chartering codebase.

## Business Domain

### Industry Context

Maritime shipping brokerage software. Three key actors:

1. **Charterers** - Companies needing commodity transport (don't own vessels)
2. **Vessel operators** - Own/manage ships (no cargo)
3. **Brokers** - Middlemen connecting charterers to vessels, negotiating contracts

**Primary users**: Brokers

### Core Entities

| Entity | Description |
|--------|-------------|
| **Cargo Order** | Request from charterer: "Move X quantity of Y product from A to B during dates Z" |
| **Fixture** | Signed contract for a cargo. Vessel is mandatory (unlike cargo where it's TBD) |
| **Tonnage** | Vessel data: position, history, rates, open positions, commercial operators |

### Data Sources

Data enters system from multiple sources per entity:

| Entity | Sources | Notes |
|--------|---------|-------|
| Cargo | `email`, `user` | Email = parsed from market notification emails |
| Fixture | `email`, `user`, `kpler` | Kpler = internal company data team |
| Tonnage | Single source | Vessel database + user additions |

**Email source workflow**: Market notification emails → parser → injection pipeline → database

**Backup mechanism**: Editing/deleting email entries first backs up original to `backup_*` table, preserving audit trail.

---

## Product Features

### Three Dashboards

1. **Tonnage List** (`/workflows/tonnage-list`)
   - Real-time vessel database with filters
   - User-created lists with saved filters
   - Vessel details: position history, past fixtures
   - Map visualization
   - Open positions management
   - Grid templates for column layouts

2. **Cargo List** (`/workflows/cargo-list`)
   - Aggregated cargo orders (email + user sources)
   - Named lists with 14 filter types
   - CRUD for both email and user-added cargos
   - Market data: TCE, rate, lumpsum, commercial status

3. **Fixture List** (`/workflows/fixtures-list`)
   - Aggregated fixtures (email + user + kpler sources)
   - Named lists with 15+ filter types
   - CRUD for user-added fixtures only
   - Status tracking: Failed, In Progress, Cancelled, Fully Fixed, Finished, Inactive

### Common Capabilities

- **List management**: Create/rename/delete named lists with saved filters
- **Column preferences**: Visibility, width, ordering persisted per user
- **Source tracking**: UI distinguishes data origin (email/user/kpler)
- **Contributor attribution**: Creator/updater metadata on all entities

---

## Backend Architecture

**Location**: `chartering-fast-api/`

**Stack**: FastAPI, SQLAlchemy 2.0 (async), PostgreSQL, Python 3.11

### Directory Structure

```
chartering-fast-api/
├── src/kpler/
│   ├── interface/              # API routers (entry points)
│   ├── application/            # Command handlers, auth
│   ├── chartering/context/     # Bounded contexts (DDD)
│   │   ├── cargo_list/         # Cargo domain
│   │   ├── fixture_list/       # Fixture domain
│   │   ├── tonnage_list/       # Tonnage domain
│   │   ├── common/             # Shared models
│   │   └── user_preferences/   # Grid/column prefs
│   └── infrastructure/         # Repos, DB, external services
├── alembic/                    # DB migrations
└── tests/, integration/        # Test suites
```

### Layered Architecture

```
Interface (routers) → Application (commands) → Domain (models) → Infrastructure (repos)
```

### Database Tables

**Cargo**:
- `email_cargo_order` - Email-sourced cargos
- `user_added_cargo_orders` - User-created cargos
- `backup_email_cargo_order` - Audit trail for email edits

**Fixture**:
- `email_fixtures` - Email-sourced
- `user_added_fixtures` - User-created
- Kpler fixtures (separate source)

### Key Patterns

#### Command/Handler Pattern

Each operation has dedicated command + handler:

```python
# src/kpler/chartering/context/cargo_list/application/
RetrieveCargoOrdersCommand/Handler  # Fetch + aggregate
AddCargoOrderCommand/Handler        # Create
UpdateUserAddedCargoOrderCommand    # Edit user cargo
DeleteCargoOrderCommand             # Delete
```

#### Repository Pattern

Abstract interfaces in domain, implementations in infrastructure:

```python
# Domain (abstract)
class CargoListRepository(ABC): ...

# Infrastructure (concrete)
class CargoListRepositoryDb(CargoListRepository): ...
```

#### History/Event Aggregation

Multiple sources merged into unified chronological list:

```python
# Cargo: 2 sources → CargoOrdersHistory
CargoOrdersHistory.from_user_and_email_cargo_orders(user_orders, email_orders)

# Fixture: 3 sources → FixturesHistory
FixturesHistory.from_user_kpler_and_email_fixtures(user, kpler, email)
```

#### Filter Objects

Encapsulate query parameters:

```python
CargoListFilters:
  source_filter, date_range, quantity_filter, laycan_range,
  commercial_status, rate, TCE, lumpsum, product, zone filters

FixtureListFilters:
  source_filter, vessel filters (IMO, type, deadweight),
  commercial_operator, status, type, demurrage filters
```

### Key API Endpoints

```
/api/v1/chartering/
├── cargo-orders/
│   ├── POST   /user-added-cargo-orders      # Create
│   ├── GET    /user-added-cargo-orders/{id} # Read
│   ├── PUT    /user-added-cargo-orders/{id} # Update
│   ├── DELETE /user-added-cargo-orders/{id} # Delete
│   ├── PUT    /email-cargo-orders/{id}      # Edit email cargo
│   ├── DELETE /email-cargo-orders/{id}      # Delete email cargo
│   └── POST   /cargo-orders                 # Search with filters
├── fixtures/
│   ├── POST   /user-added-fixtures          # Create
│   ├── PUT    /user-added-fixtures/{id}     # Update
│   ├── DELETE /user-added-fixtures/{id}     # Delete
│   └── POST   /fixtures                     # Search with filters
├── cargo-lists/                             # List CRUD
├── fixture-lists/                           # List CRUD
└── tonnage-list/                            # Tonnage operations
```

### Organization IDs

Two ID types for multi-tenancy:
- `KplerOrganizationId` - User's Kpler org (for user-added data)
- `MtiOrganizationId` - Email source org (for email data)

### Database Config

```python
# Read/write splitting
write_async_engine  # CHARTERING_HOST
read_async_engine   # CHARTERING_HOST_RO (read replica)
```

---

## Frontend Architecture

**Location**: `web-app/apps/terminal/src/domains/chartering/`

**Stack**: Vue 3, RxJS, ag-Grid, TypeScript

### Directory Structure

```
chartering/
├── TheCargoListWorkspace/      # Cargo list feature
│   ├── observableApis/         # RxJS state management
│   ├── hooks/                  # Vue composables
│   ├── services/               # API calls
│   ├── components/             # Vue components
│   └── columnDefinitions/      # ag-Grid columns
├── TheTonnageListWorkspace/    # Tonnage list feature
│   ├── observableApis/
│   ├── hooks/
│   ├── components/
│   └── ...
├── domain/
│   └── fixtures/               # Fixture list feature
│       ├── hooks/
│       ├── services/
│       ├── components/
│       └── utils/
├── httpClient/
│   └── generated/              # Auto-generated OpenAPI SDK
└── types/                      # Shared TypeScript types
```

### State Management Pattern

RxJS observables bridged to Vue 3:

```typescript
// Create mutable observable
export const cargoTypeFilter$ = ObservableWithNext.fromValue<FilterType>(null);

// Use in component
const cargoTypeFilter = useObservableAsComputed(cargoTypeFilter$);

// Update state
cargoTypeFilter$.next(newValue);
```

**Key files per feature**:
- `observableApis/*.ts` - State observables (filters, selected list, etc.)
- `hooks/use*.ts` - Vue composables wrapping observables + API calls

### Source-Based Polymorphism

Row-level `source` field determines CRUD endpoint:

```typescript
// CargoGridRowItem
type CargoGridRowItem = {
  source: 'email' | 'user';
  rowId: number;
  // ...
};

// Edit dispatches to correct endpoint
if (originalCargoOrder.source === 'email') {
  await updateEmailCargoOrder(payload);
} else {
  await updateUserCargoOrder(payload);
}
```

### Key Types

```typescript
// Cargo
type CargoOrder = {
  product?: ProductFragment;
  destination?: ZoneFragment;
  laycan: { start: string; end: string };
  loadArea: ZoneFragment | null;
  quantity: CargoQuantity;
  contractType: 'VC' | 'TCT';
  charterer?: ChartererFragment;
};

// Fixture
type FixtureEventResponse = {
  id: string;
  fixture: FixtureResponse;
  source: 'KPLER' | 'USER_ADDED' | 'EMAIL';
  update_metadata: UpdateMetadataDto | null;
  user_metadata: FixtureUserMetadataResponse | null;
  email_metadata: FixtureEmailMetadataResponse | null;
};

// Shared fragments (loaded via hydration)
type ProductFragment = { id: number; name: string; parentId?: number };
type ZoneFragment = { id: number; name: string; type: string };
type VesselFragment = { id: number; imo: string; name: string };
type ChartererFragment = { id: number; name: string };
```

### Hydration Pattern

API returns IDs, frontend loads full objects separately:

```typescript
// hydrateFixturesList.ts
const [products, zones, vessels, players] = await Promise.all([
  hydrateProducts(productIds),
  hydrateZones(zoneIds),
  hydrateVessels(imoList),
  hydratePlayersById(playerIds),
]);
```

### Filter Transformation

Domain filters ↔ DTO conversion:

```typescript
// Domain → API
convertFiltersToDto(filters: FixturesListFilters): FixturesSearchDto

// API → Domain
transformDtoToFilters(dto: FixturesListDto): FixturesListFilters
```

### API Client

Auto-generated from OpenAPI spec:

```typescript
// httpClient/generated/sdk.gen.ts
createOrderApiV1CharteringUserAddedCargoOrdersPost(body)
deleteOrderApiV1CharteringUserAddedCargoOrdersCargoOrderIdDelete(id)
searchCargoOrdersByFiltersApiV1CharteringCargoOrdersPost(filters)
```

**Config** (`customAxios.ts`):
```typescript
baseURL: process.env.NX_PUBLIC_CHARTERING_BACKEND_URL
```

### Component Patterns

**Workspace wrapper** → **Display component** → **Table + Sidebar**

```
CargoListWrapper.vue
└── DisplayCargoList.vue
    ├── CargoListTable.vue (ag-Grid)
    └── Sidebar (list management)
```

**ag-Grid columns**: Defined in `columnDefinitions/` with custom cell renderers.

---

## Key Files Reference

### Backend

| Purpose | Path |
|---------|------|
| Main app entry | `src/kpler/interface/main.py` |
| Cargo domain models | `src/kpler/chartering/context/cargo_list/domain/` |
| Fixture domain models | `src/kpler/chartering/context/fixture_list/domain/` |
| Cargo commands | `src/kpler/chartering/context/cargo_list/application/` |
| Fixture commands | `src/kpler/chartering/context/fixture_list/application/` |
| DB models | `src/kpler/infrastructure/database/models/` |
| Repositories | `src/kpler/infrastructure/repositories/` |
| DB config | `src/kpler/infrastructure/database/database.py` |
| Routers | `src/kpler/interface/routers/` |

### Frontend

| Purpose | Path |
|---------|------|
| Cargo workspace | `TheCargoListWorkspace/` |
| Cargo state | `TheCargoListWorkspace/observableApis/` |
| Cargo hooks | `TheCargoListWorkspace/hooks/` |
| Tonnage workspace | `TheTonnageListWorkspace/` |
| Fixtures domain | `domain/fixtures/` |
| Fixtures services | `domain/fixtures/services/` |
| Fixtures hooks | `domain/fixtures/hooks/` |
| Generated API client | `httpClient/generated/sdk.gen.ts` |
| Generated types | `httpClient/generated/types.gen.ts` |
| Shared types | `types/` |

---

## Common Operations

### Adding a New Filter

**Backend**:
1. Add field to filter dataclass in `application/` command
2. Update repository query in `infrastructure/repositories/`
3. Add to API schema in router

**Frontend**:
1. Add to filter type in relevant `types/` file
2. Create filter observable in `observableApis/`
3. Add transformer in `utils/filterTransformers.ts`
4. Create filter UI component
5. Wire into FilterBar component

### Adding a New Field to Cargo/Fixture

**Backend**:
1. Add to domain model in `context/*/domain/`
2. Add to DB model in `infrastructure/database/models/`
3. Create Alembic migration
4. Update repository mapping
5. Update API DTOs in router

**Frontend**:
1. Regenerate API client (if backend OpenAPI updated)
2. Add to domain type
3. Add column definition for ag-Grid
4. Update create/edit forms if needed

### Creating a New Endpoint

**Backend**:
1. Create command + handler in `application/`
2. Add router function in `interface/routers/`
3. Wire repository calls
4. Add tests

**Frontend**:
1. Regenerate API client
2. Create service function wrapping SDK call
3. Create hook using `useRequest` pattern
4. Wire into component

---

## Conventions

### Backend

- Async everywhere (`async def`, `await`)
- Type hints on all functions
- Pydantic models for API schemas
- SQLAlchemy models for DB
- Repository pattern for data access
- Command/handler for business logic

### Frontend

- RxJS observables for shared state
- Vue 3 composition API
- `use*` prefix for hooks
- `*$` suffix for observables
- Services for API calls, hooks for state + UI logic
- ag-Grid for all tables

### Naming

- `UserAdded*` - User-created entities
- `Email*` - Email-sourced entities
- `Kpler*` - Kpler internal data
- `*Fragment` - Lightweight reference type (id + name)
- `*Dto` - Data transfer object (API payload)
- `*History` - Aggregated multi-source list
