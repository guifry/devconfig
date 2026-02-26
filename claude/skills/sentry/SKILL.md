---
name: sentry
description: Sentry CLI for investigating errors, issues, events, and logs. Use when asked to check Sentry, look up an error, investigate a crash, or debug a production issue.
allowed-tools: Bash
---

# Sentry CLI

## Two CLIs — Know Which One You're Using

There are two Sentry CLIs:

| CLI | Binary | Purpose |
|-----|--------|---------|
| **Developer CLI** (`sentry`) | `sentry` | Issues, events, AI analysis, logs — developer workflow |
| **Build/CI CLI** (`sentry-cli`) | `sentry-cli` | Release management, source maps, debug symbols — CI/CD |

For investigating errors in production: use `sentry`. For release tracking in builds: use `sentry-cli`.

---

## Installation

```bash
# Recommended
curl -fsSL https://cli.sentry.dev/install | bash

# Homebrew (macOS)
brew install getsentry/tools/sentry

# npm/npx (no install needed)
npx sentry@latest issue list
```

For `sentry-cli`:
```bash
brew install getsentry/tools/sentry-cli
# or
curl -sL https://sentry.io/get-cli/ | sh
```

---

## Authentication

### Developer CLI (`sentry`)

**OAuth (recommended — opens browser):**
```bash
sentry auth login
```

**API token (headless/CI):**
```bash
sentry auth login --token YOUR_SENTRY_API_TOKEN
```

Credentials stored at `~/.sentry/config.json` (mode 600).

**Check auth status:**
```bash
sentry auth whoami
```

**Log out:**
```bash
sentry auth logout
```

### Build CLI (`sentry-cli`)

**Interactive:**
```bash
sentry-cli login
# saves token to ~/.sentryclirc
```

**Environment variable (preferred for CI):**
```bash
export SENTRY_AUTH_TOKEN=your_token
export SENTRY_ORG=your-org
export SENTRY_PROJECT=your-project
```

**Config file** (`~/.sentryclirc`):
```ini
[auth]
token=your_token

[defaults]
org=your-org
project=your-project
```

**Verify:**
```bash
sentry-cli info
```

### Troubleshooting Auth

| Symptom | Fix |
|---------|-----|
| `401 Unauthorized` | Token expired — run `sentry auth login` again |
| `403 Forbidden` | Token lacks scope — generate new token with `org:read`, `project:read`, `event:read` scopes |
| `sentry: command not found` | Not installed or not in PATH — check `~/.local/bin/sentry` or reinstall |
| `sentry-cli: command not found` | Run `brew install getsentry/tools/sentry-cli` |
| Works locally, fails in CI | Set `SENTRY_AUTH_TOKEN` env var in CI secrets |
| Self-hosted instance | Add `--url https://your-sentry.com` or set `url=` in `[defaults]` of `~/.sentryclirc` |

---

## Developer CLI: Issue Workflows

### List Issues

```bash
# Auto-detect project from .env / DSN in current directory
sentry issue list

# Specific project
sentry issue list my-org/my-project

# All projects in org
sentry issue list my-org/

# Filters
sentry issue list -q "is:unresolved"                    # unresolved only (default)
sentry issue list -q "is:unresolved level:error"        # errors only
sentry issue list -q "is:unresolved assigned:me"        # assigned to me
sentry issue list -q "TypeError"                        # text search
sentry issue list -q "is:unresolved !has:assignee"      # unassigned

# Sort options: date (default), new, freq, user
sentry issue list -s freq                               # most frequent first
sentry issue list -s new                                # newest first

# Time period (default: 90d)
sentry issue list -t 24h
sentry issue list -t 7d
sentry issue list -t 14d

# Limit results (default: 25, max: 1000)
sentry issue list -l 50

# JSON output for scripting
sentry issue list --json | jq '.[].title'
```

### View an Issue

```bash
# By issue ID or short ID
sentry issue view PROJ-123
sentry issue view 123456789

# Open in browser
sentry issue view PROJ-123 --web
sentry issue view PROJ-123 -w

# JSON with full event data and trace
sentry issue view PROJ-123 --json
```

### AI Root Cause Analysis (Seer)

```bash
# Get AI explanation of what went wrong
sentry issue explain PROJ-123

# Force fresh analysis (ignores cached result)
sentry issue explain PROJ-123 --force

# JSON output
sentry issue explain PROJ-123 --json
```

Takes up to a few minutes for newly created issues.

---

## Developer CLI: Event Workflows

### View an Event

```bash
# By event ID
sentry event view <event-id>

# Explicit org/project
sentry event view my-org/my-project <event-id>

# Open in browser
sentry event view <event-id> -w

# JSON output
sentry event view <event-id> --json
```

---

## Developer CLI: Logs

```bash
# Historical logs
sentry log list --project=my-project --org=my-org

# Stream logs in real-time (tail -f equivalent)
sentry log list --project=my-project --org=my-org --live
```

---

## Developer CLI: Other Commands

```bash
# List orgs
sentry org list

# List projects
sentry project list

# List projects in an org
sentry project list my-org

# Direct API call (escape hatch for anything not covered)
sentry api GET /organizations/my-org/issues/ -q "is:unresolved"
sentry api GET /projects/my-org/my-project/events/
```

---

## Build CLI: Release Management

Used in CI/CD to associate deploys with commits for blame/regression tracking.

```bash
VERSION=$(sentry-cli releases propose-version)   # auto from git

sentry-cli releases new "$VERSION"
sentry-cli releases set-commits "$VERSION" --auto
sentry-cli releases finalize "$VERSION"
sentry-cli releases deploys new --release "$VERSION" -e production
```

---

## Build CLI: Source Maps

```bash
sentry-cli sourcemaps upload ./dist \
  --url-prefix "~/" \
  --strip-common-prefix \
  --validate
```

---

## Common Investigative Workflows

### "What's broken in production right now?"
```bash
sentry issue list -q "is:unresolved level:error" -s freq -t 24h -l 20
```

### "Find all errors in a specific file"
```bash
sentry issue list -q "is:unresolved stack.abs_path:*event_injection.py*"
```

### "Investigate a specific crash"
```bash
sentry issue view PROJ-123                   # see the issue
sentry issue explain PROJ-123                # AI root cause
sentry event view <latest-event-id> --json  # raw event data
```

### "What new errors appeared after the last deploy?"
```bash
sentry issue list -q "is:unresolved age:-2h" -s new
```

### "All unassigned errors assigned to no one"
```bash
sentry issue list -q "is:unresolved !has:assignee level:error" -s freq
```

### "Pipe into jq for scripting"
```bash
sentry issue list --json | jq '[.[] | {id: .id, title: .title, count: .count}]'
```

---

## Query Syntax Reference (`-q` flag)

| Filter | Example |
|--------|---------|
| Status | `is:unresolved` `is:resolved` `is:ignored` |
| Level | `level:error` `level:warning` `level:fatal` |
| Assignment | `assigned:me` `assigned:username` `!has:assignee` |
| Text search | `TypeError` `"cannot read property"` |
| File | `stack.abs_path:*filename.py*` |
| Tag | `environment:production` `release:1.2.3` |
| Age | `age:-24h` (newer than 24h) |
| Has field | `has:assignee` `!has:assignee` |

---

## Tokens and Scopes

Generate tokens at: **Sentry UI → Settings → Auth Tokens**

Minimum scopes needed:
- `org:read` — list orgs, projects
- `project:read` — list/view issues
- `event:read` — view events
- `project:releases` — release management (build CLI)
- `project:write` — upload source maps / debug files
