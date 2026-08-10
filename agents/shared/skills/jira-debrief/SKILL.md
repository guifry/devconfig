---
name: jira-debrief
description: Fetch Jira sprint state, tickets, blockers. Use for standup prep, sprint review, ticket status.
allowed-tools: Bash, Read
---

# Jira Board Debrief

Fetch Guilhem's current sprint state using auto-detection via JQL.

## User Context
- User: Guilhem Forey
- Project: CMDT (Commodities)

## Auto-Detection
Use `openSprints()` JQL function - no hardcoded board/sprint config needed.

## Queries

### My Tickets (Active Sprint)
```jql
sprint in openSprints() AND assignee = currentUser() ORDER BY status, priority DESC
```

### Blocked/Flagged
```jql
sprint in openSprints() AND assignee = currentUser() AND (status = Blocked OR flagged = flagged)
```

### Recently Updated by Team (last 24h)
```jql
sprint in openSprints() AND updated >= -24h AND assignee != currentUser() ORDER BY updated DESC
```

### Tickets Needing Review
```jql
sprint in openSprints() AND status = "User validation" ORDER BY updated DESC
```

## Output Format

**My Tickets by Status:**
| Key | Summary | Status | Priority |
|-----|---------|--------|----------|

**Status Summary:**
- To Do: X
- In Progress: X
- In Review/Validation: X
- Done (this sprint): X

**Blockers:**
- [ticket] blocked by: reason

**Team Updates (24h):**
- @person moved [ticket] to Done
- @person started [ticket]

**Needs My Attention:**
- [ticket] awaiting review
- [ticket] has new comment
