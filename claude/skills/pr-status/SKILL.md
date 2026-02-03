# PR Status

Fetch GitHub PR status and create actionable todos.

## Steps

1. **PRs awaiting my review:**
```bash
gh pr list --search "review-requested:@me" --json number,title,url,author,createdAt,isDraft
```

2. **My open PRs + their status:**
```bash
gh pr list --author @me --json number,title,url,state,reviewDecision,statusCheckRollup,comments
```

3. **Comments/reviews on my PRs I haven't responded to:**
```bash
gh api graphql -f query='{ viewer { pullRequests(first: 20, states: OPEN) { nodes { number title url reviewRequests(first:5) { totalCount } reviews(last:5) { nodes { author { login } state body } } comments(last:5) { nodes { author { login } body } } } } } }'
```

## Output Format

**PRs to review:** (oldest first, flag if >24h)
- [ ] #123 "title" by @author - [link]

**My PRs status:**
- #456 "title" - approved / pending review / changes requested / CI failing
  - Unaddressed comments: X

**Action items:**
- Respond to @X on #456
- Review #123 (requested 2d ago)
