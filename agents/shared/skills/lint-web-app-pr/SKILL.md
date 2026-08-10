---
name: lint-web-app-pr
description: Run ESLint and type-check on files changed in the current PR (web-app monorepo). Fast alternative to full CI.
allowed-tools: Bash, Read, Grep, Glob
---

# Web App PR Lint & Type Check

Run ESLint and vue-tsc only on files changed by the current branch, mirroring what CI does but much faster.

## Prerequisites

Must be run from inside a `web-app` git worktree (any FST instance or the main clone).

## Execution Steps

### 1. Locate web-app root

```bash
WEB_APP_ROOT=$(git rev-parse --show-toplevel)
echo "Web app root: $WEB_APP_ROOT"
ls "$WEB_APP_ROOT/apps/terminal/package.json" >/dev/null 2>&1 || { echo "ERROR: not inside a web-app worktree"; exit 1; }
```

### 2. Find changed files

Get all `.ts` and `.vue` files changed on this branch vs `origin/main`:

```bash
cd "$WEB_APP_ROOT"
BASE=$(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main)
CHANGED_FILES=$(git diff --name-only "$BASE"...HEAD -- '*.ts' '*.vue' | grep -v 'node_modules' | grep -v '.gen.ts')
echo "$CHANGED_FILES"
```

If no files changed, report clean and stop.

### 3. Run ESLint on changed files only

```bash
cd "$WEB_APP_ROOT/apps/terminal"
echo "$CHANGED_FILES" | sed "s|^|../../|" | xargs npx eslint --quiet 2>&1
```

Notes:
- Paths are relative to `apps/terminal/` so prefix with `../../`
- Uses `--quiet` to suppress warnings (matches CI `lint:ci` behaviour)
- Files outside `apps/terminal/` scope will be silently skipped by ESLint

If ESLint fails, report each error with file path and line number. Offer to auto-fix with `--fix`.

### 4. Run type check (full, but incremental)

Type checking cannot be scoped to individual files — `vue-tsc` needs the full project graph. But incremental builds make repeated runs fast.

```bash
cd "$WEB_APP_ROOT/apps/terminal"
npx vue-tsc --noEmit 2>&1
```

If type errors are found, report each with file path and line number.

### 5. Report

Summarise:
- Number of files linted
- ESLint: pass / N errors found
- Type check: pass / N errors found
- If errors exist, list them grouped by file
- Suggest fixes where obvious
