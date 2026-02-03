# Slack Debrief

Summarise unread Slack activity from last 24h.

## Prerequisites
Requires Slack MCP configured in settings.json with SLACK_BOT_TOKEN and SLACK_TEAM_ID.

## Steps

1. **Fetch direct mentions** - messages where user was @mentioned
2. **Fetch DMs** - unread direct messages
3. **Fetch channel updates** - from subscribed/priority channels
4. **Fetch threads** - replies to threads user participated in

## Output Format

**Requires response:**
- @person in #channel: "message summary" - action needed: [respond/review/decide]

**FYI - should read:**
- #channel: discussion about X (Y messages)
- @person DM: "summary"

**Low priority:**
- General updates, announcements

**Suggested replies:**
- To @person re: X -> suggested response outline
