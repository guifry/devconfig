---
description: Frontend-specific context and patterns
paths:
  - web-app/**
  - web-app-*/**
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

## Atlas Component Library (`@kpler/ui-vue3`)

**Rule: always use an Atlas component when one exists.** Avoid custom/handmade implementations for the sake of design consistency. Import from `@kpler/ui-vue3`:
```typescript
import { AtlasButton, AtlasDialog, AtlasInput } from '@kpler/ui-vue3';
```

### Component Catalogue

AtlasAlert / Important messages with icons and optional close button
AtlasAlertDialog / Modal confirmation dialog with action buttons
AtlasAvatar / User profile image with fallback initials
AtlasBadge / Small label with optional icon and removal
AtlasButton / Action button with variants, sizes, icon support
AtlasCalendar / Date picker calendar (daily/monthly/yearly)
AtlasCascader / Multi-level hierarchical selector with tree expansion
AtlasCheckbox / Toggleable checkbox with label and indeterminate state
AtlasCollapsible / Expandable/collapsible content container
AtlasCombobox / Searchable dropdown, single or multi-select
AtlasDateField / Editable date input with validation
AtlasDatePicker / Date selector with popover and presets
AtlasDatePresets / Quick-select date shortcuts
AtlasDateRangeField / Date range input with start/end validation
AtlasDateRangePicker / Range date selector with calendar and presets
AtlasDateRangePresets / Preset date range shortcuts
AtlasDateTimePicker / Combined date + time selector with timezone
AtlasDialog / Modal dialog with header, body, footer
AtlasDropdownMenu / Context menu with items and submenus
AtlasIcon / SVG icon renderer with size options
AtlasInput / Text input with label, icons, validation messages
AtlasLabel / Text label with variant styling
AtlasNavigation / Sidebar nav with collapsible sections and pinning
AtlasNotificationPill / Small dot indicator for status/notifications
AtlasNumberField / Numeric input with increment/decrement and validation
AtlasPagination / Page navigation with total records and page size
AtlasPopover / Floating container anchored to trigger element
AtlasRadioGroup / Single-selection radio button group
AtlasRangeCalendar / Calendar for selecting date ranges
AtlasResizablePanelGroup / Resizable panel container with drag dividers
AtlasScrollArea / Scrollable container with custom scrollbars
AtlasSeparator / Horizontal/vertical divider line
AtlasSheet / Side panel drawer sliding from edge
AtlasSonner / Toast notification system
AtlasSwitch / Toggle switch with optional label
AtlasTabs / Tabbed interface with multiple sections
AtlasTabsMenu / Navigation menu bar using tab structure
AtlasTimeInput / Time picker for hours and minutes
AtlasToggle / Single button toggling pressed state
AtlasToggleGroup / Group of toggles with single selection
AtlasTooltip / Floating label on hover
AtlasTree / Hierarchical tree view with expansion and selection
AtlasWorkspaceLayout / Page layout with sticky header

**IMPORTANT: when implementing frontend features or developing new components, if this list is not clear enough or you need more detail on a component's props, slots, or usage patterns, read the component source code and stories directly at `web-app/core/ui/vue3/src/components/{ComponentName}/`. Each component has a `.vue` source, `.stories.ts` with usage examples, and often a `.docs.md` with documentation.**

## Design Sizing & Spacing Rules (CRITICAL — MUST FOLLOW)

**These rules are derived from the designer's Figma specifications and are NON-NEGOTIABLE. Every UI element must follow these sizing conventions. Violating them produces chunky, oversized interfaces that do not match the product design. When in doubt, go smaller.**

### Element Sizing

| Element | Size | Atlas prop | Notes |
|---------|------|------------|-------|
| **Inputs, Comboboxes, Selects** | 28px height | `size="sm"` | NEVER use default/md (36px) |
| **Toggle groups** | 28px height | `size="sm"` | 12px text inside |
| **Inline/secondary buttons** | 28px height | `size="sm"` | "Browse", "Nominate vessels", toolbar actions |
| **Dialog footer buttons** | 36px height | `size="md"` | Cancel/Submit — the ONLY place md is used for buttons |
| **Badges** | 20px height | `size="sm"` | 12px text |
| **Tabs** | 32px height | — | 12px text |
| **Icons** | 10-12px | — | Consistently small, never larger |

### Typography

| Context | Size | Weight |
|---------|------|--------|
| **Body text, labels, values, descriptions** | `text-xs` (12px) | `normal` (400) |
| **Form labels** | `text-xs` (12px) | `medium` (500) |
| **Badge text** | `text-xs` (12px) | `normal` (400) |
| **Tab labels** | `text-xs` (12px) | `medium` (500) |
| **Primary button text** | `text-sm` (14px) | `medium` (500) |
| **Dialog headers** | `text-lg` (18px) | `semibold` (600) |
| **Unit suffixes** ($/Mt, $/day, hrs) | `text-[11px]` | `normal` (400) |

**`text-xs` (12px) is the baseline for nearly everything. `text-sm` (14px) is ONLY for primary action button labels. Never default to `text-sm` for general UI text.**

### Spacing

| Between | Gap |
|---------|-----|
| Label → input | `gap-0.5` (2px) |
| Elements within a field | `gap-1` (4px) |
| Form field rows | `gap-2` (8px) |
| Form sections | `gap-4` (16px) |
| Major content sections | `gap-6` (24px) |

### Visual Subtlety

- Secondary data values: `opacity-80` for de-emphasis
- Muted text colour: `var(--muted-foreground)` / `text-muted-foreground` for labels and secondary info
- Border colour at 50% opacity on cards: `var(--border-50%)` / `border-border/50`
- Focus areas (term summaries): `bg-slate-50` with `rounded-sm` and `p-3`

### Quick Reference for Common Patterns

```vue
<!-- Input field (ALWAYS sm) -->
<AtlasInput size="sm" />

<!-- Combobox (ALWAYS sm) -->
<AtlasCombobox size="sm" />

<!-- Inline button (sm) -->
<AtlasButton size="sm" variant="secondary">Browse</AtlasButton>

<!-- Dialog footer buttons (md — the ONLY exception) -->
<AtlasButton size="md" variant="ghost">Cancel</AtlasButton>
<AtlasButton size="md">Submit</AtlasButton>

<!-- Toggle group (sm) -->
<AtlasToggleGroup size="sm">...</AtlasToggleGroup>

<!-- Badge (sm) -->
<AtlasBadge size="sm">Draft</AtlasBadge>
```
