# Standup Prep

Orchestrate daily debrief and prepare standup talking points.

## Flow

### 1. Gather Context (parallel)
Run these skills to collect current state:
- `/pr-status` - GitHub PRs
- `/slack-debrief` - Slack updates
- `/jira-debrief` - Jira board

### 2. Interactive Q&A
Ask user:

**Yesterday:**
- "What did you complete yesterday?" (cross-ref with Jira tickets moved to Done)
- "Any tickets you worked on but didn't finish?"

**Blockers:**
- "Are you blocked on anything?"
- "Need decisions from anyone?"

**Today:**
- "What's your focus today?" (suggest based on Jira priorities + PR reviews pending)

### 3. Generate Output

**Standup Script:**
```
Yesterday:
- Completed [ticket] - brief description
- Worked on [ticket] - progress note

Today:
- Focus on [ticket]
- Review PR #X from @person

Blockers:
- [if any]
```

**Comms To-Do:**
- [ ] Respond to @X on Slack re: Y
- [ ] Review PR #123
- [ ] Update [ticket] with progress

**Day Priorities:** (numbered, max 3)
1. Most important task
2. Second priority
3. Third priority

**Week Context:** (if Monday)
- Sprint goal reminder
- Key deadlines this week
- Meetings to prep for

**Team Mentions:**
- Things to flag to team
- Help needed from specific people
