---
name: playwright-browser
description: Playwright browser profiles for authenticated web automation. Create profiles, log in once, reuse sessions via MCP plugin.
allowed-tools: Bash, Read, Write
---

# Playwright Browser — Persistent profile automation

Self-contained Playwright profiles with full session persistence. Log in once, automate forever.

**No Chrome dependency.** Runs as a separate Chromium instance while Chrome stays open.

## DO NOT

- **DO NOT write Python scripts** to automate the browser. Never use `launch_persistent_context` in scripts.
- **DO NOT run `playwright-auth open`** from within Claude Code — it blocks the session.
- **DO NOT modify `~/.claude.json`** or any global config to add Playwright MCP servers.
- **DO NOT use the default MCP plugin profile** at `~/Library/Caches/ms-playwright/`. Always use `~/.playwright-profiles/`.
- **DO NOT hardcode a profile name in the MCP plugin config.** The config is global — use the wrapper script + env var pattern.

## DO

- **DO use the MCP plugin tools** (`browser_navigate`, `browser_snapshot`, `browser_click`, `browser_type`, etc.) to interact with the browser. These are your only interface.
- **DO use `playwright-auth`** CLI to create and manage profiles in `~/.playwright-profiles/`.
- **DO set `PLAYWRIGHT_PROFILE` in each project's `.envrc`** to select the right profile per project.

## Architecture

Two components work together:

1. **`playwright-auth` CLI** — manages named profiles in `~/.playwright-profiles/`. Used to create profiles and log in manually.
2. **Playwright MCP plugin** — provides `browser_*` tools to Claude Code. Uses a wrapper script that reads `PLAYWRIGHT_PROFILE` env var to select the right profile.

### How they connect

The MCP plugin config lives at:
```
~/.claude/plugins/marketplaces/claude-plugins-official/external_plugins/playwright/.mcp.json
```

It points to a wrapper script (not directly to npx):
```json
{
  "playwright": {
    "command": "/Users/guilhemforey/.playwright-profiles/playwright-mcp-wrapper.sh"
  }
}
```

The wrapper script (`~/.playwright-profiles/playwright-mcp-wrapper.sh`) reads `PLAYWRIGHT_PROFILE` from the environment and passes `--user-data-dir` to the MCP server:
```bash
#!/bin/bash
PROFILE="${PLAYWRIGHT_PROFILE:-default}"
PROFILE_DIR="$HOME/.playwright-profiles/$PROFILE"
if [ ! -d "$PROFILE_DIR" ]; then
  mkdir -p "$PROFILE_DIR"
fi
exec npx @playwright/mcp@latest --user-data-dir "$PROFILE_DIR" "$@"
```

### Per-project profile selection

Each project sets `PLAYWRIGHT_PROFILE` in its `.envrc`:
```bash
# ~/projects/taisk-forecast-backend/.envrc
export PLAYWRIGHT_PROFILE=taisk-admin

# ~/projects/some-other-project/.envrc
export PLAYWRIGHT_PROFILE=work
```

direnv loads the right env var per directory. The MCP plugin picks up the right profile automatically. **No MCP config changes needed when switching projects.**

If no `PLAYWRIGHT_PROFILE` is set, falls back to a `default` profile.

## Setup workflow

### 1. Create a profile
```bash
playwright-auth create my-profile
# Browser opens → log into services → close browser
```

### 2. Set the profile in your project's `.envrc`
```bash
echo 'export PLAYWRIGHT_PROFILE=my-profile' >> .envrc
direnv allow
```

### 3. Restart Claude Code (only needed on first setup or after MCP config changes)

### 4. Use `browser_*` MCP tools — already authenticated

## Profile management CLI: `playwright-auth`

```bash
playwright-auth list [--json]       # List profiles
playwright-auth create <name>       # Create profile + launch browser for login
playwright-auth open <name> [url]   # Open browser with profile (for re-auth)
playwright-auth delete <name>       # Delete a profile
```

## MCP tools available

All prefixed with `mcp__playwright__`:

- `browser_navigate` — go to a URL
- `browser_snapshot` — accessibility tree of current page (preferred over screenshot)
- `browser_click` — click element by ref
- `browser_type` — type text (use `slowly: true` for autocomplete fields)
- `browser_fill_form` — fill form fields
- `browser_take_screenshot` — visual screenshot
- `browser_press_key` — press a keyboard key
- `browser_hover` — hover over element
- `browser_navigate_back` — go back
- `browser_tabs` — list open tabs
- `browser_wait_for` — wait for page state
- `browser_console_messages` — read console logs
- `browser_network_requests` — inspect network
- `browser_evaluate` — run JS in page context
- `browser_select_option` — select from dropdowns
- `browser_drag` — drag elements
- `browser_file_upload` — upload files
- `browser_handle_dialog` — handle browser dialogs
- `browser_resize` — resize viewport
- `browser_close` — close browser

## Interaction pattern

1. **`browser_snapshot`** — read the page. Returns accessibility tree with `ref=eNNNN` on every interactive element.
2. **Identify target** — find the right `ref` from the snapshot.
3. **`browser_click`** / **`browser_type`** — interact using `ref`.
4. **Check result** — action returns a snapshot diff. No need to snapshot again after each action.
5. **Repeat.**

### Tips
- Snapshot (accessibility tree) is far more useful than screenshots — gives exact refs and semantic structure.
- For combobox/autocomplete: use `browser_type` with `slowly: true` to trigger suggestions, then click one.
- Dismiss overlays/tooltips before clicking elements behind them.
- After each action, the tool returns only what changed. Call `browser_snapshot` explicitly if you need full context.

## Refreshing sessions

If authentication expires:
```bash
playwright-auth open my-profile https://accounts.google.com
# Re-authenticate, close browser
```
Then restart Claude Code.

## Files

```
~/.playwright-profiles/
├── playwright-mcp-wrapper.sh   # Wrapper script (reads PLAYWRIGHT_PROFILE env var)
├── taisk-admin/                # guilhem@taisk.com — Supabase, Vercel, Stripe, GitHub, FreeAgent
├── taisk-owner/                # Taisk app testing as owner
├── edy-forey/                  # edyforey@gmail.com — Google, Squarespace
├── kpler-local/                # Work profile
└── owner-profile/              # Another profile
```

## What persists

| Data | Persisted |
|------|-----------|
| Cookies | Yes |
| localStorage | Yes |
| IndexedDB | Yes |
| Session tokens | Yes |
| Saved passwords | Yes |
| Extensions | Yes (if installed) |
