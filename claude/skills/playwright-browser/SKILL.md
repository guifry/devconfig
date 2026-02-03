---
name: playwright-browser
description: Manage Chrome profiles for Playwright - list profiles, add/refresh auth state, launch browser with saved credentials
allowed-tools: Bash, Read, Write
---

# Playwright Browser — Web automation with Chrome auth

Storage state snapshots from Chrome profiles let Playwright start "already logged in" to authenticated services. Chrome can stay open during all operations — the script copies profiles before reading them.

## CLI: `playwright-auth`

```bash
playwright-auth list          # Show Chrome profiles + state profiles
playwright-auth add           # Add new state profile (interactive)
playwright-auth refresh NAME  # Refresh a state profile
playwright-auth refresh-all   # Refresh all state profiles
```

## Examples

**User: "What Chrome profiles do I have?"**
```bash
playwright-auth list
```

**User: "Set up my work profile for Playwright"**
```bash
playwright-auth add
# Then select "Work" from the list
```

**User: "Check my Jira dashboard using work profile"**
```bash
playwright-auth list  # Verify work.json exists
```
Then write Python:
```python
import asyncio
import os
from playwright.async_api import async_playwright

async def main():
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=False)
        context = await browser.new_context(
            storage_state=os.path.expanduser('~/.playwright-auth/work.json')
        )
        page = await context.new_page()
        await page.goto('https://jira.atlassian.com')
        # ... extract data ...
        await browser.close()

asyncio.run(main())
```

**User: "My work profile auth seems expired"**
```bash
playwright-auth refresh work
```

**User: "Update all my Playwright profiles"**
```bash
playwright-auth refresh-all
```

**User: "Which profile has my AWS credentials?"**
```bash
playwright-auth list
```
Then ask user which profile name corresponds to their AWS account.

**User: "Add my personal Chrome profile for Playwright"**
```bash
playwright-auth add
# Select "Personal" or equivalent from the interactive list
```

**User: "Set up my client-x profile" (name doesn't match exactly)**
```bash
playwright-auth list
```
Output shows available profiles. If no exact match for "client-x":
> I don't see a profile named "client-x". Here are the available Chrome profiles:
> - Work (Profile 1)
> - Personal (Default)
> - Acme Corp (Profile 2)
> Which one would you like to use?

**User: "Screenshot my GitHub notifications using personal profile"**
```bash
playwright-auth list  # Verify personal.json exists
```
Then write Python script with `storage_state='~/.playwright-auth/personal.json'`

**User: "How much disk space do profiles need?"**
```bash
playwright-auth list  # Shows sizes for each profile
```

**User: "Delete a state profile I no longer need"**
```bash
rm ~/.playwright-auth/old-profile.json
```
