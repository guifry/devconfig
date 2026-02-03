---
name: playwright-browser
description: Chrome profiles and Playwright automation. Use for listing profiles, browser auth, web scraping behind logins, storage state management.
allowed-tools: Bash, Read, Write
---

# Playwright Browser — Web automation with Chrome auth

Storage state snapshots from Chrome profiles let Playwright start "already logged in" to authenticated services.

**Chrome MUST be closed for add/refresh operations.** The script copies Chrome profile data which is locked while Chrome runs.

## Requirements

- Python 3 with playwright: `pip install playwright`
- Chromium browser: `playwright install chromium`

## CLI: `playwright-auth`

```bash
playwright-auth list [--json]           # Show profiles (--json for agent parsing)
playwright-auth add                     # Add state profile (interactive)
playwright-auth add PROFILE STATE [--yes]  # Add state profile (non-interactive)
playwright-auth refresh NAME [--yes]    # Refresh a state profile
playwright-auth refresh-all [--yes]     # Refresh all state profiles
```

## Non-Interactive Usage (for agents)

**List profiles (JSON for parsing)**
```bash
playwright-auth list --json
```

**Create state profile by email**
```bash
playwright-auth add guilhem@taisk.com taisk --yes
```

**Create state profile by folder**
```bash
playwright-auth add "Profile 11" taisk --yes
```

**Refresh a profile**
```bash
playwright-auth refresh work --yes
```

**Refresh all profiles**
```bash
playwright-auth refresh-all --yes
```

**Check if Chrome running (must close for add/refresh)**
```bash
pgrep -q "Google Chrome" && echo "Chrome running - close it first" || echo "Chrome not running - safe to proceed"
```

**Get profile folder from email**
```bash
playwright-auth list --json | jq -r '.chrome_profiles[] | select(.email=="guilhem@taisk.com") | .folder'
```

**Check if state profile exists**
```bash
playwright-auth list --json | jq -r '.state_profiles[].name' | grep -q "^work$" && echo "exists" || echo "not found"
```

**Use storage state in Python script**
Write and execute:
```python
import asyncio
import os
from playwright.async_api import async_playwright

async def main():
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=False)
        context = await browser.new_context(
            storage_state=os.path.expanduser('~/.playwright-auth/taisk.json')
        )
        page = await context.new_page()
        await page.goto('https://example.com')
        # ... do stuff ...
        await browser.close()

asyncio.run(main())
```

## Interactive Usage (human only)

**Add new profile interactively**
```bash
playwright-auth add
# Follow prompts: select profile, enter name, close Chrome when prompted
```

## Examples

**User: "What Chrome profiles do I have?"**
```bash
playwright-auth list --json
```

**User: "Set up my taisk profile for Playwright"**
```bash
playwright-auth list --json | jq -r '.chrome_profiles[] | select(.email | contains("taisk"))'
playwright-auth add guilhem@taisk.com taisk --yes
```

**User: "Check my Jira dashboard using work profile"**
```bash
playwright-auth list --json | jq -r '.state_profiles[].name' | grep -q "^work$"
```
Then write Python with `storage_state='~/.playwright-auth/work.json'`

**User: "My work profile auth seems expired"**
```bash
playwright-auth refresh work --yes
```

**User: "Delete a state profile I no longer need"**
```bash
rm ~/.playwright-auth/old-profile.json
```
