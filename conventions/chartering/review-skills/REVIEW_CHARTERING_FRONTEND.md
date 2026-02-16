# Chartering Frontend PR Review

Review all changes on current branch against coding standards and architecture patterns.

## Execution Steps

### 1. Identify Changes

```bash
BASE=$(git merge-base HEAD main 2>/dev/null || git merge-base HEAD develop 2>/dev/null || git merge-base HEAD master)
git diff $BASE --name-only
git diff $BASE
```

### 2. Read Conventions

Read `CLAUDE.md` (FST root) for all coding standards, then this file for frontend-specific checks.

### 3. Check Architecture Layer Violations

The chartering frontend follows a strict 5-layer architecture. For each changed file, verify it respects its layer's responsibilities:

| Layer | Directory | Responsibility | May import |
|-------|-----------|----------------|------------|
| **Observable APIs** | `observableApis/` | RxJS state, DTO↔domain conversion, API calls | Generated SDK, types |
| **Services** | `services/` | Orchestration, dispatching to correct observable | Observable APIs, types |
| **Hooks** | `hooks/` | Thin wrappers bridging observables to Vue reactivity | Services, observable APIs |
| **Components** | `components/`, `*.vue` | UI rendering, user interaction, toast, emit | Hooks only (never services/observableApis directly) |
| **Column Definitions** | `columnDefinitions/columns/` | AG Grid + export formatter pairs | Types only |

**Common violations:**

- ❌ Component importing a service or observable API directly
- ❌ Component building a DTO (domain→API conversion belongs in service/observableApi)
- ❌ Hook containing business logic (should be a thin wrapper)
- ❌ Observable API importing Vue reactivity (`ref`, `computed`)
- ❌ Service handling UI concerns (toast, emit, dialog state)

**Auto-fix by moving logic to the correct layer.**

### 4. Check Observable State Pattern

For every new observable in the diff:

1. Writable observables use `ObservableWithNext<T>` and end with `$` suffix
2. Read-only computed observables use `ObservableWithValue<T>`
3. Each async operation has the trio: `loading$`, `error$`, `data$`
4. Mutation only via `.next()` — never direct reassignment
5. Hooks bridge to Vue via `useObservableAsComputed()`

```typescript
// ❌ BAD — direct state in component
const isLoading = ref(false);
isLoading.value = true;
await apiCall();
isLoading.value = false;

// ✅ GOOD — observable in service, hook bridges to component
// service:
export const isLoading$ = ObservableWithNext.fromValue(false);
export const doThing = async () => {
  isLoading$.next(true);
  try { await apiCall(); } finally { isLoading$.next(false); }
};
// hook:
const isLoading = useObservableAsComputed(isLoading$);
```

**Auto-fix: extract loading/error state to service observable, wrap in hook.**

### 5. Check DTO ↔ Domain Conversion Placement

For every API call in the diff:

1. Domain→DTO conversion must be in `observableApis/` or `services/`, never in components
2. DTO→Domain conversion must be in `observableApis/` (response transformation)
3. Converter functions are named `domainArgsToPayloadDto()` or `transform{Source}To{Target}()`
4. Domain types use camelCase, DTO types use snake_case

```typescript
// ❌ BAD — conversion in component
const payload = { zone_id: Number(cargo.loadArea.id) };
await api.create(payload);

// ✅ GOOD — conversion in service/observableApi
const buildPayload = (item: CargoGridRowItem): ApiPayload => ({
  zone_id: Number(item.cargoOrder.loadArea.id),
});
export const createItem = async (item: CargoGridRowItem) => {
  await api.create(buildPayload(item));
};
```

**Auto-fix: move conversion function to service layer.**

### 6. Check Type Conventions

For every new type in the diff:

| Suffix | Usage | Example |
|--------|-------|---------|
| `Fragment` | Partial/reference sub-entity (ID + name) | `VesselFragment`, `ChartererFragment` |
| `Dto` | API response/request types (snake_case fields) | `CargoOrderUpdateQuery` |
| `Payload` | Structured data sent to API | `CargoPayload` |
| No suffix | Domain types (camelCase fields) | `CargoOrder`, `CargoGridRowItem` |
| `Filter` | Filter range types with `gte`/`lte` | `TceFilter`, `RateFilter` |

Nullability rules:
- Use `| null` not `| undefined` for optional nullable fields
- Optional + nullable: `field?: Type | null`
- Ranges: both bounds nullable: `{ gte: number | null; lte: number | null }`

**Flag violations. Auto-fix naming and nullability.**

### 7. Check Hook Pattern

Every hook must follow the thin wrapper pattern:

```typescript
// ✅ GOOD — thin wrapper
export const useDoThing = () => {
  const isLoading = useObservableAsComputed(isLoading$);
  return { isLoading, doThing };
};

// ❌ BAD — business logic in hook
export const useDoThing = () => {
  const doThing = async (args) => {
    const payload = buildPayload(args);  // ← belongs in service
    await api.call(payload);
  };
  return { doThing };
};
```

**Auto-fix: extract logic to service, keep hook as thin bridge.**

### 8. Check Column Definition Pattern

For every new or modified column in `columnDefinitions/columns/`:

1. File exports `{ agGridDefinition, exportDefinition }` satisfying `ColumnDefinition`
2. `COL_ID` constant at top, used in both definitions
3. Both `agGridDefinition` and `exportDefinition` have matching `colId` and `headerName`
4. Uses `satisfies AgColumnDefinition` / `satisfies ExportColumnDefinition`
5. Column is added to the ordered array in `columns/index.ts`

**Auto-fix formatting. Flag missing index entry.**

### 9. Check Feature Flag Usage

For every new feature flag reference:

1. Flag constant defined in `featureFlags.constants.ts`
2. Correct pattern used:
   - Route guard → factory function in routes (Pattern A)
   - UI toggle → composable in component (Pattern B)
   - Route redirect → `beforeEnter` guard (Pattern C)
3. Never hardcode flag strings — always use `CHARTERING_FEATURE_FLAGS.X`

**Auto-fix: extract hardcoded strings to constants.**

### 10. Check File Naming

| Category | Convention | Example |
|----------|-----------|---------|
| Vue components | PascalCase `.vue` | `AddCargoOrderModal.vue` |
| TypeScript files | camelCase `.ts` | `cargoListFilters.ts` |
| Services | `{domain}.service.ts` | `editCargoOrder.service.ts` |
| Hooks | `use{Feature}.ts` | `useAddCargoOrder.ts` |
| Column defs | `{fieldName}.ts` | `vesselName.ts` |
| Types | `types.ts` | `DisplayCargoList/types.ts` |
| Constants | `{feature}.constants.ts` | `featureFlags.constants.ts` |
| Transformers | `{domain}Transformers.ts` | `contactTransformers.ts` |

**Flag misnamed files.**

### 11. Verify New Code Is Used

For every new public function, type, or component in the diff:

1. Search the codebase for usages beyond the definition
2. Flag unused exports
3. Pay attention to:
   - Hook functions — is the hook imported by a component?
   - Service functions — is the service called by a hook or observable?
   - Types — are they referenced in components, hooks, or services?
   - Components — are they used in a template or route?

**Only flag code added in this branch's diff. Remove dead code.**

### 12. Check Code Style

For each changed file:
- No comments unless explaining non-obvious logic
- No docstrings
- No AI-generated TODO/FIXME markers
- All imports at file top
- No nested ternary operators — use if/else or switch
- No `as any` type casts — use proper typing or `as unknown as Type` with justification
- British English in user-facing strings

**Auto-fix violations.**

### 13. Run Lint

```bash
pnpm --filter terminal run lint
```

Fix failures and re-run until clean.

### 14. Run Type Check

```bash
npx vue-tsc --noEmit --project apps/terminal/tsconfig.json
```

Fix type errors and re-run until clean.

### 15. Report Status

Summarise:
- Layer violations found and fixed
- Conversion placement issues found and fixed
- Dead code found and removed
- Type convention issues found and fixed
- Lint status
- Type check status
- Ready to push: Yes/No
- Any unfixable issues requiring manual intervention
