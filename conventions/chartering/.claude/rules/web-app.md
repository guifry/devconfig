---
description: Frontend-specific context and patterns
paths:
  - web-app/**
---

# Web App Rules

## Chartering Domain Location
`apps/terminal/src/domains/chartering/` — all chartering code lives here.
Adjacent domains: `domains/fixr/`, `domains/contactManagement/`

## Key Patterns

### Observable State (RxJS)
State flows through observables, not Vuex/Pinia:
- `ObservableWithNext<T>` wraps BehaviorSubject with `.next()` for writes
- `useObservableAsComputed()` bridges RxJS → Vue reactivity
- Chain: selectedCargoListId$ → cargoListAllFilters$ → fetchCargoOrdersFromFilters

### API Client
Generated from OpenAPI: `@kpler/chartering-api` package
- Types: `httpClient/generated/types.gen.ts`
- SDK: `httpClient/generated/sdk.gen.ts`
- Naming: `{verb}{Entity}ApiV1Chartering{Path}{Method}`
- Regen: `npx @hey-api/openapi-ts`

### Feature Flags (two-layer)
1. Vuex: `store.getters.userHasPermission('feature_flag:tonnage_list')`
2. Growthbook: `useFeatureFlag(CHARTERING_FEATURE_FLAGS.MY_FLAG)`
- Pattern A: factory route guard (teaser page) — for workspaces
- Pattern B: composable hook (v-if) — for UI elements
- Pattern C: beforeEnter guard (redirect) — for contact management
- Full reference: `docs/codebase/web-app/FEATURE_FLAGGING.md`

### Column Definitions (AG Grid)
Each column: separate file in `columnDefinitions/columns/`, exports `ColDef`.
Custom renderers via `cellRendererFramework`. Ordered array in `columns/index.ts`.

### Navigation
`hooks/useCharteringNavigation.ts` — `CharteringRouteKeys` enum.
Add new nav items here + corresponding route in workspace routes.
