---
name: playwright-browser
description: Playwright browser profiles for authenticated web automation. Create profiles, log in once, reuse sessions.
allowed-tools: Bash, Read, Write
---

# Playwright Browser — Persistent profile automation

Self-contained Playwright profiles with full session persistence. Log in once, automate forever.

**No Chrome dependency.** Runs as a separate Chromium instance while Chrome stays open.

## Requirements

- Python 3 with playwright: `pip install playwright`
- Chromium browser: `playwright install chromium`

## CLI: `playwright-auth`

```bash
playwright-auth list [--json]       # List profiles
playwright-auth create <name>       # Create profile + launch browser for login
playwright-auth open <name> [url]   # Open browser with profile
playwright-auth delete <name>       # Delete a profile
```

## Workflow

**1. Create profile and log in**
```bash
playwright-auth create foray
# Browser opens → log into FreeAgent, Google, etc. → close browser
```

**2. Use in scripts**
```python
import asyncio
import os
from playwright.async_api import async_playwright

async def main():
    async with async_playwright() as p:
        context = await p.chromium.launch_persistent_context(
            user_data_dir=os.path.expanduser('~/.playwright-profiles/foray'),
            headless=False,
            args=['--disable-blink-features=AutomationControlled']
        )
        page = context.pages[0] if context.pages else await context.new_page()
        await page.goto('https://www.freeagent.com/dashboard')
        # Already logged in!
        await context.close()

asyncio.run(main())
```

**3. Refresh sessions when needed**
```bash
playwright-auth open foray https://accounts.google.com
# Re-authenticate if sessions expired
```

## Non-Interactive Usage (for agents)

**List profiles (JSON)**
```bash
playwright-auth list --json
```

**Check if profile exists**
```bash
playwright-auth list --json | jq -r '.profiles[].name' | grep -q "^foray$" && echo "exists" || echo "not found"
```

**Get profile path**
```bash
playwright-auth list --json | jq -r '.profiles[] | select(.name=="foray") | .path'
```

**Delete without confirmation**
```bash
playwright-auth delete old-profile --yes
```

## Files

```
~/.playwright-profiles/
├── foray/           # Full Chromium profile (cookies, localStorage, IndexedDB)
├── work/            # Another profile
└── personal/        # Another profile
```

## What Persists

| Data | Persisted |
|------|-----------|
| Cookies | ✅ |
| localStorage | ✅ |
| IndexedDB | ✅ |
| Session tokens | ✅ |
| Saved passwords | ✅ |
| Extensions | ✅ (if installed) |

## Examples

**User: "Set up a profile for my work accounts"**
```bash
playwright-auth create work
# Log in to Jira, GitHub, Slack, etc.
```

**User: "Check my FreeAgent dashboard"**
```bash
playwright-auth list --json | jq -r '.profiles[].name' | grep -q "^foray$"
```
Then write Python with `user_data_dir='~/.playwright-profiles/foray'`

**User: "My Google session expired"**
```bash
playwright-auth open work https://accounts.google.com
# Re-authenticate
```

**User: "Delete my old test profile"**
```bash
playwright-auth delete test --yes
```

## Headless Mode

For background automation, change `headless=False` to `headless=True`:

```python
context = await p.chromium.launch_persistent_context(
    user_data_dir=os.path.expanduser('~/.playwright-profiles/foray'),
    headless=True
)
```

Note: Some sites detect headless browsers. Use `headless=False` if you encounter issues.
