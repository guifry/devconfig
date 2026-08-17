---
name: branch-report
description: Report of all outstanding PRs, local branches, and stacks for the current repo. Stack detection, orphan branch discovery.
allowed-tools: Bash
---

# Branch & PR Report

Generate a report of outstanding PRs, local branches, and stacks for the current repo.

## Steps

1. **Get repo context and default branch:**
```bash
DEFAULT_BRANCH=$(gh repo view --json defaultBranchRef -q '.defaultBranchRef.name')
echo "$DEFAULT_BRANCH"
```

2. **Fetch all open PRs by current user from last 2 weeks:**
```bash
TWO_WEEKS_AGO=$(date -v-14d +%Y-%m-%d 2>/dev/null || date -d '14 days ago' +%Y-%m-%d)
gh pr list --author @me --state open --json number,title,url,headRefName,baseRefName,createdAt,isDraft,reviewDecision,statusCheckRollup --limit 100 | \
  jq --arg since "$TWO_WEEKS_AGO" '[.[] | select(.createdAt >= $since)]'
```

3. **Build stack tree from PR data.** Group PRs into stacks by following `baseRefName` chains:
   - If PR's `baseRefName` matches another PR's `headRefName`, they're in the same stack
   - The root of a stack targets the default branch (main/master)
   - A standalone PR (targets default branch, no other PR targets it) is its own stack of 1

4. **Find local branches with recent commits that have no open PR:**
```bash
DEFAULT_BRANCH=$(gh repo view --json defaultBranchRef -q '.defaultBranchRef.name')
TWO_WEEKS_AGO=$(date -v-14d +%Y-%m-%d 2>/dev/null || date -d '14 days ago' +%Y-%m-%d)

# Get all PR branch names for exclusion
PR_BRANCHES=$(gh pr list --author @me --state open --json headRefName -q '.[].headRefName')

git fetch origin "$DEFAULT_BRANCH" --quiet 2>/dev/null

for branch in $(git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads/); do
  # Skip default branch
  [ "$branch" = "$DEFAULT_BRANCH" ] && continue

  # Skip if this branch has an open PR
  echo "$PR_BRANCHES" | grep -qx "$branch" && continue

  # Check last commit date
  LAST_COMMIT_DATE=$(git log -1 --format=%cs "$branch" 2>/dev/null)
  [ -z "$LAST_COMMIT_DATE" ] && continue
  [[ "$LAST_COMMIT_DATE" < "$TWO_WEEKS_AGO" ]] && continue

  # Count unique commits vs merge-base with default branch
  MERGE_BASE=$(git merge-base "$branch" "origin/$DEFAULT_BRANCH" 2>/dev/null)
  [ -z "$MERGE_BASE" ] && continue
  UNIQUE_COMMITS=$(git rev-list --count "$MERGE_BASE..$branch" 2>/dev/null)
  [ "$UNIQUE_COMMITS" = "0" ] && continue

  echo "$branch|$LAST_COMMIT_DATE|$UNIQUE_COMMITS"
done
```

5. **For no-PR branches, detect stacking against PR branches:**
```bash
# For each no-PR branch, check if any PR branch tip is an ancestor
for pr_branch in $PR_BRANCHES; do
  git merge-base --is-ancestor "$pr_branch" "$branch" 2>/dev/null && echo "stacked on $pr_branch"
done
```
If no PR branch is an ancestor, it's based on the default branch.

6. **Skip branches with 0 unique commits** (already filtered in step 4).

## Output Format

Render the full report as markdown. Use this structure:

```
## Branch & PR Report — {repo name}

### PR Stacks

**Stack: {root PR title}**
└── #{number} `branch-name` — {title} [{status}]({url})
    └── #{number} `branch-name` — {title} [{status}]({url})
        └── #{number} `branch-name` — {title} [{status}]({url})

**Standalone PRs**
- #{number} `branch-name` — {title} [{status}]({url})

### Local Branches (no PR)

| Branch | Based on | Commits | Last commit |
|--------|----------|---------|-------------|
| `feat/foo` | `feat/bar` (PR #123) | 3 | 2025-03-10 |
| `fix/baz` | main | 1 | 2025-03-09 |
```

**Status values:** draft, review pending, approved, changes requested, CI failing, merged.
Derive status from `isDraft`, `reviewDecision`, and `statusCheckRollup`.

### Notes

- Run all `gh` commands as-is — they use whichever GitHub auth is currently active.
- If `gh pr list` returns nothing, report "No open PRs in the last 2 weeks."
- If no local branches qualify, omit the "Local Branches" section.
- If the repo has no remote, report error and stop.
- Handle both macOS (`date -v-14d`) and Linux (`date -d '14 days ago'`) date syntax.
