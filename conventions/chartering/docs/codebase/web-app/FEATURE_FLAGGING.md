# Feature Flagging in Chartering Domain

## Two-Layer System

Chartering uses a two-layer feature flag system:

### Layer 1: Vuex Permissions (coarse-grained)

Backend-assigned permissions stored in Vuex store. Checked synchronously.

**Key permissions:**
```
feature_flag:tonnage_list          # Access to tonnage/cargo/fixtures
feature_flag:chartering_dev        # Access to dev/experimental features
feature_flag:chartering_new_features   # Access to new features
```

**Check pattern:**
```typescript
store.getters.userHasPermission('feature_flag:tonnage_list')
```

**Note:** `feature_flag:tonnage_list` gates ALL chartering features, not just tonnage.
Both cargo list and fixtures check the same permission. This is intentional.

### Layer 2: Growthbook Flags (fine-grained)

Client-side feature flags via Growthbook (gradual rollout, A/B testing).

**Package:** `@kpler/feature-flag-vue3`

**Current flags:**
```typescript
// permissions/featureFlags.constants.ts
export const CHARTERING_FEATURE_FLAGS = {
  NEXT_PORT_CALL_TRACK: 'enableFutureTrackTLMap',
  CARGO_ORDER_PANEL: 'cargoOrderPanel',
  SUBVIEW_EMAILS_AND_PARSER: 'subviewEmailsAndParser',
  TONNAGE_GROUP_BY_ZONES: 'tonnageGroupByZones',
  COMMERCIAL_STATUS_COLUMN: 'commercialStatusColumn',
};
```

**Contact management flag (in fixr domain):**
```typescript
// domains/fixr/constants.ts
export const CONTACT_MANAGEMENT_FEATURE_FLAG = 'chartering:contact-list';
```

---

## Implementation Patterns

### Pattern A: Route Guard with Factory Function

**Used for:** Protecting entire workspaces (tonnage list, cargo list, fixtures)

**File:** `permissions/useCharteringPermissions.ts`

```typescript
export const userHasTonnageListPermissionFactory = (store: AppStore) => () =>
  store.getters.userHasPermission('feature_flag:tonnage_list');

export const userHasCargoListPermissionFactory = (store: AppStore) => () =>
  store.getters.userHasPermission('feature_flag:tonnage_list');

export const userHasFixturesPermissionFactory = (store: AppStore) => () =>
  store.getters.userHasPermission('feature_flag:tonnage_list');

export const userHasParserPermissionFactory = (store: AppStore) => () =>
  store.getters.userHasPermission('feature_flag:tonnage_list') &&
  store.getters.userHasPermission('feature_flag:chartering_dev') &&
  (featureFlagService?.isOn(CHARTERING_FEATURE_FLAGS.SUBVIEW_EMAILS_AND_PARSER) ?? false);
```

**Usage in routes:**
```typescript
const CargoListWrapper = () =>
  userHasCargoListPermissionFactory(store)()
    ? import('./CargoListWrapper/CargoListWrapper.vue')    // Full access
    : import('./CargoListPreview.vue');                     // Teaser page
```

**How it works:**
1. Factory creates a permission checker bound to the store
2. Route component dynamically imports based on permission
3. Users without permission see a preview/teaser page
4. No redirect, just different component

### Pattern B: Composable Hook with Computed

**Used for:** Conditional UI rendering within components

**File:** `hooks/useSubviewEmailsAndParser.ts`

```typescript
export const useSubviewEmailsAndParser = () => {
  const { userHasAccessToCharteringDev } = useCharteringFeatureFlags();
  const subviewEmailsAndParserFlag = useFeatureFlag(
    CHARTERING_FEATURE_FLAGS.SUBVIEW_EMAILS_AND_PARSER,
  );

  const hasSubviewEmailsAndParserAccess = computed(
    () => userHasAccessToCharteringDev.value && subviewEmailsAndParserFlag.value,
  );

  return { hasSubviewEmailsAndParserAccess };
};
```

**Usage in template:**
```vue
<template>
  <EmailsTab v-if="hasSubviewEmailsAndParserAccess" />
</template>
```

**How it works:**
1. Hook combines Vuex permission + Growthbook flag
2. Returns reactive computed boolean
3. Components conditionally render based on access
4. Two-layer: must have BOTH Vuex permission AND Growthbook flag

### Pattern C: Route beforeEnter Guard

**Used for:** Contact management (different pattern from chartering)

```typescript
beforeEnter: async (to, _from, next) => {
  const { featureFlagService } = await import('...');
  const { store } = await import('...');

  // Lazy-init feature flag service
  if (store.state.user.user && !featureFlagService?.isInitialized) {
    await featureFlagService?.init(store.state.user.user);
  }

  // Register and check flag
  featureFlagService?.registerFlag(CONTACT_MANAGEMENT_FEATURE_FLAG);

  if (!featureFlagService?.isOn(CONTACT_MANAGEMENT_FEATURE_FLAG)) {
    return nextWithRefresh(getHomepageRoute(store.state.settings.homepage));
  }

  return next();
};
```

**How it works:**
1. Lazy-loads dependencies (code splitting)
2. Initialises feature flag service if needed
3. Registers the flag (ensures it's tracked)
4. Redirects to homepage if flag is off
5. Different from Pattern A: redirects instead of showing teaser

---

## Feature Flag Hook Base Pattern

**File:** `hooks/useCharteringFeatureFlags.ts`

```typescript
const NEW_FEATURES_FF = 'feature_flag:chartering_new_features';
const CHARTERING_DEV = 'feature_flag:chartering_dev';

export const useCharteringFeatureFlags = () => {
  const store = useInjectStore();

  const userHasAccessToNewFeatures = computed(() =>
    checkPermission(store, NEW_FEATURES_FF)
  );
  const userHasAccessToCharteringDev = computed(() =>
    checkPermission(store, CHARTERING_DEV)
  );

  return {
    userHasAccessToNewFeatures,
    userHasAccessToCharteringDev,
  };
};
```

All chartering feature flag hooks import from here as the base.

---

## How to Add a New Feature Flag (Step-by-Step)

### Step 1: Define the Growthbook flag constant

```typescript
// permissions/featureFlags.constants.ts
export const CHARTERING_FEATURE_FLAGS = {
  // ... existing flags ...
  MY_NEW_FEATURE: 'myNewFeature',
};
```

### Step 2: Create the access hook

```typescript
// hooks/useMyNewFeature.ts
import { useFeatureFlag } from '@kpler/feature-flag-vue3';
import { computed } from 'vue';
import { useCharteringFeatureFlags } from './useCharteringFeatureFlags';
import { CHARTERING_FEATURE_FLAGS } from '../permissions/featureFlags.constants';

export const useMyNewFeature = () => {
  const { userHasAccessToCharteringDev } = useCharteringFeatureFlags();
  const myNewFeatureFlag = useFeatureFlag(CHARTERING_FEATURE_FLAGS.MY_NEW_FEATURE);

  const hasMyNewFeatureAccess = computed(
    () => userHasAccessToCharteringDev.value && myNewFeatureFlag.value,
  );

  return { hasMyNewFeatureAccess };
};
```

### Step 3a: Protect a route (Pattern A - show teaser)

```typescript
// permissions/useCharteringPermissions.ts
export const userHasMyNewFeaturePermissionFactory = (store: AppStore) => () =>
  store.getters.userHasPermission('feature_flag:tonnage_list') &&
  store.getters.userHasPermission('feature_flag:chartering_dev') &&
  (featureFlagService?.isOn(CHARTERING_FEATURE_FLAGS.MY_NEW_FEATURE) ?? false);
```

```typescript
// routes.ts
const MyFeatureWrapper = () =>
  userHasMyNewFeaturePermissionFactory(store)()
    ? import('./MyFeature.vue')
    : import('./MyFeaturePreview.vue');
```

### Step 3b: Conditional rendering (Pattern B)

```vue
<script setup>
import { useMyNewFeature } from '../hooks/useMyNewFeature';
const { hasMyNewFeatureAccess } = useMyNewFeature();
</script>

<template>
  <NewFeatureComponent v-if="hasMyNewFeatureAccess" />
</template>
```

### Step 4: Register flag in Growthbook

Create the flag in the Growthbook dashboard with:
- Flag key matching the constant value
- Targeting rules (specific users, orgs, percentage rollout)

---

## Important Notes

- **Vuex permissions** are set server-side and cannot be changed without backend
- **Growthbook flags** can be toggled in real-time via dashboard
- **Both layers must pass** for access to be granted
- **`feature_flag:chartering_dev`** is the standard gate for experimental features
- **`feature_flag:tonnage_list`** is the base gate for all chartering access
- **Preview/teaser pages** are preferred over redirects for better UX
- **Feature flag service** (`featureFlagService`) is a singleton from `src/app/providers/singletons/featureFlagService`
- **`useFeatureFlag()`** returns a reactive ref from `@kpler/feature-flag-vue3`
