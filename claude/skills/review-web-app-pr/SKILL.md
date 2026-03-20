---
name: review-web-app-pr
description: Review web-app PR changes against team patterns extracted from 247 merged PRs (Dec 2025 – Mar 2026).
allowed-tools: Bash, Read, Grep, Glob, Edit, Write
---

# Web App PR Review

Review all changes on the current branch against frontend patterns and conventions established by the team. Patterns sourced from 247 merged PRs with 7800+ review comments (Dec 2025 – Mar 2026).

## Execution Steps

### 1. Identify Changes

```bash
WEB_APP_ROOT=$(git rev-parse --show-toplevel)
BASE=$(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main)
git diff $BASE --name-only -- '*.ts' '*.vue' '*.tsx' | grep -v node_modules | grep -v '.gen.ts'
git diff $BASE --stat
```

Read each changed file in full before reviewing.

### 2. Vue Template Patterns

For each changed `.vue` file, check:

- **No unnecessary `<template>` wrappers**: put `v-if` directly on the component, not on a wrapping `<template>` tag around a single child
- **No `props.` prefix in templates**: access props directly by name — `props.` prefix is unnecessary noise
- **No anonymous functions in templates**: define event handlers in `<script setup>`, reference them by name in the template
- **No inline complex class conditions**: extract complex boolean expressions in `:class` bindings into named computed properties
- **`class` attribute last**: place `class` as the last attribute on elements
- **Use `defineModel()`** for v-model bindings instead of manual prop + get/set computed
- **Use `computed()`** for derived values instead of watch + manual ref mutation
- **Use `ref()`** not `reactive()` for component state
- **Use `<form>` with `@submit.prevent`** for form-like UIs, `type="submit"` on primary button
- **Use Atlas `required` prop** on form inputs instead of manual asterisks in labels
- **Use `as-child`** on AtlasButton when wrapping another element (e.g. `<a>`)
- **Use `for` + `id`** for label-input association (accessibility)
- **Icon-only buttons** must have `aria-label` and a tooltip
- **No popover inside popover**: use flat lists or AtlasTree for cascading selection
- **Use `data-testid`** for test selectors, never `id` attributes
- **Remove empty `<style>` tags**
- **No redundant `v-if` guards**: if the parent already conditionally renders with `v-if`, don't re-check the same condition inside the child
- **Use `visibility:hidden`** instead of off-screen positioning (e.g. `-top-96`) for measurement elements
- **Atlas component defaults**: don't set props that already match the component's default value
- **Choose correct Atlas component**: AtlasDropdownMenu for action lists, AtlasPopover for rich interactive content, AtlasCombobox for search/select

### 3. Date / Time Patterns

For each changed file that manipulates dates, check:

- **Use `moment` for all date operations**: formatting, comparison, arithmetic, duration. Never use native `Date` for these — the codebase convention is `moment.utc()` throughout chartering
- **No `new Date(x).toLocaleDateString()`**: use `moment.utc(x).format('D MMM YYYY')` or similar
- **No `new Date(x).getTime() - new Date().getTime()`**: use `moment.utc(x).diff(moment.utc())`
- **No `new Date(x) < new Date()`**: use `moment.utc(x).isBefore(moment.utc())`
- **No `new Date(); now.setHours(...)` for date arithmetic**: use `moment.utc().add(hours, 'hours')`
- **`new Date()` is OK only** for reactive timestamp refs (e.g. timer ticks) — all formatting/comparison of that value must still go through moment
- **Extract shared formatters into domain utils**: if `formatDate`/`formatCurrency`/`humanise` appear in multiple components, they belong in a shared utils file (e.g. `utils/formatting.ts`), not copy-pasted per component

### 4. TypeScript Patterns

For each changed `.ts` / `<script>` block, check:

- **No `as` type casts in mocks/tests**: mock data should satisfy its type naturally
- **No `as unknown as X`**: find the correct type or add a type guard
- **No magic strings**: define enums or typed constants for discrete value sets (event types, statuses, frequencies)
- **Type mock data** using generated API client types or GraphQL schema types
- **No `async` without `await`**: remove async keyword from functions that don't use await
- **Tuple types for fixed-length arrays**: use `[string, string]` not `string[]` when length is known
- **Guard nullable properties before string interpolation**: check for undefined before template literals to avoid rendering "undefined"
- **Prefer union string types over enums** for simple value sets: `type Position = 'top-left' | 'top-right'`
- **Reuse library types**: check if the library already exports an equivalent type before creating a new one
- **Derive types from constants**: `type X = (typeof OBJ)[keyof typeof OBJ]` instead of duplicating
- **Simplify boolean computeds**: `x === Y` already returns false when x is undefined — no extra nullish check needed

### 4. Tailwind / CSS Patterns

For each changed template or style section, check:

- **No Tailwind class strings extracted into JS constants**: keep classes inline in the template. If duplication is excessive, extract a component instead
- **No dynamic Tailwind class construction**: never `tw-mt-${size}` — Tailwind scans statically. Use complete class strings
- **Semantic design tokens over hardcoded colours**: use `tw-bg-background`, `tw-text-muted-foreground` not `tw-bg-gunmetal-900`
- **No legacy SCSS variables or theme files** in new code: use Tailwind classes + Atlas design tokens
- **No `:global` CSS selectors**
- **No `!important` (`!tw-`) unless proven specificity conflict**
- **Remove redundant classes**: audit `tw-w-full`, `tw-min-h-0` etc. that are inherited from parent flex/grid context
- **Use padding/margin not whitespace characters** for spacing
- **Avoid negative margins** to compensate parent gaps: wrap child in a plain `<div>` instead
- **Use `text-ellipsis`** not `overflow-ellipsis` (correct Tailwind v3 class name)
- **AG Grid theming**: use CSS custom properties mapped to Atlas `theme()` values, not legacy SCSS

### 5. Architecture Patterns

For each changed file, check:

- **Extract async/API logic from components** into composables or service files: components should focus on UI orchestration
- **Separate column config from data fetching** in hooks (separation of concerns)
- **Hooks folder outside components folder**: `components/` should only contain `.vue` files
- **Cross-domain API calls in separate service files**: e.g. `freight.service.ts` inside the arbitrage domain
- **Composables must return values**: only use `use` prefix if it returns reactive state. Side-effect functions use action verbs
- **Pass callbacks into hooks** to keep them decoupled from router/app concerns
- **Break large hooks into named sub-functions**: extract logical steps (setupImages, addCorrelatedLayer)
- **Module-scope refs for shared state**: if a composable's state needs sharing across consumers, declare ref outside the function
- **No business logic in `*.utils.ts`**: utils are pure transformations, business logic lives near its consumers
- **API base URLs from env variables**: never hardcoded conditional logic
- **Prefer `fetch` over `axios`** for new API clients
- **Loading/error/empty wrapper**: when multiple components repeat the same pattern, extract it
- **Feature-flag-to-item mapping**: prefer declarative mapping over per-item composables
- **Place domain config in domain folder**, not in global app-level directories

### 6. Naming Conventions

For each changed identifier, check:

- **No abbreviations**: full descriptive names (e.g. `userTradingIntelligencePackages` not `userTIPackages`). Only well-known domain acronyms (IMO, AIS) are OK
- **Constants in UPPER_SNAKE_CASE** and in the domain's `constants.ts` file
- **Function params match object keys** for shorthand syntax: `(emailFrequency) => ({ emailFrequency })` not `(freq) => ({ emailFrequency: freq })`
- **Handlers named after what they do**: `handleModalOpen` not `createContact` (if it just opens a modal)
- **Feature flags scoped with domain prefix**: `chartering:contact-list` not `contact-list`
- **Consistent V2 naming**: include "V2" in all filenames, variables, mocks when coexisting with V1
- **V2 in separate files**: create v2 files/directories rather than v2-suffixed functions inside existing files
- **Icon literals extracted to constants**
- **No formatting-only changes** in feature PRs — keep diffs focused
- **Configure ESLint/Prettier on save**: formatting issues should never appear in PRs

### 7. Testing Patterns

For each changed test file, check:

- **Mock feature flags** when features are behind flags
- **Type mock data** with generated API types
- **Use `data-qa` / `data-testid` selectors**, not CSS class selectors
- **Use semantic locators**: `getByRole`, `getByText` over raw selectors
- **Assert initial state before testing transitions**: e.g. check element is hidden before the action that shows it
- **Screenshots alone are not sufficient**: add explicit assertions (toBeVisible, toBeHidden, text content)
- **After delete operations**: mock the subsequent fetch with updated data and verify UI reflects removal
- **Mock API calls close to usage**: not in shared setup unless truly called on every page load
- **Verify UI-to-API contract**: intercept requests and verify payloads
- **Test URL/query param sync** bidirectionally for filter-based pages
- **Small viewports for screenshot tests**: minimum size, expand only when needed
- **Feature-flag tests in feature-flags directory**: only tests that verify flag on/off behaviour
- **No blanket console error suppressions** in Playwright tests
- **No duplicate test cases**: review for redundant assertions
- **Split long test helpers into named sub-functions**
- **Minimal comments in tests**: test names should be self-documenting

### 8. Code Quality

For each changed file, check:

- **No dead code**: remove unused methods, imports, variables after refactoring
- **No unnecessary intermediate variables**: return expressions directly unless the variable name adds documentation value
- **No duplicate functions**: if two functions have identical logic, merge into one
- **Extract repeated checks (3+ occurrences)** into named helper functions
- **Granular try-catch**: wrap specific operations, not large blocks
- **Always `.catch()` promises in watchers**
- **Always reset loading state** in `finally` blocks
- **Combine adjacent guard clauses** that share the same action
- **Guard logic inside the function**, not at every call site
- **No single-export barrel files**: don't create `index.ts` that re-exports a single item
- **Separate types, constants, utils into distinct files**: don't mix in one file
- **Minimal comments**: remove boilerplate and obvious comments. Only genuinely non-obvious logic
- **Verify AI-generated code**: AI tools frequently invert boolean conditions silently
- **After rebasing**: check for duplicated utility functions introduced by conflict resolution
- **Use `git rev-parse --show-toplevel`** in scripts instead of fragile relative paths
- **Use pnpm catalog references** for shared tooling versions

### 9. Performance

For each changed file, check:

- **Single loop instead of multiple `.filter()` passes** when partitioning arrays
- **Use `Set` for membership checks** in large arrays
- **Use `.once()` for one-time event listeners** (e.g. map load) to prevent memory leaks
- **`readonly` on array types** unless mutation is genuinely needed (e.g. `defineModel`)

### 10. Report

Summarise:
- Violations found per category (Vue, TS, Tailwind, Architecture, Naming, Testing, Quality, Performance)
- Auto-fixed vs flagged for manual review
- Files reviewed
- Critical issues vs minor nits
- Ready to push: Yes/No
